pragma solidity ^0.4.24;

contract MonkeyEvents {

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

    // fired whenever an affiliate is paid
    event onAffiliatePayout
    (
        uint256 indexed affiliateID,
        address affiliateAddress,
        bytes32 affiliateName,
        uint256 indexed buyerID,
        uint256 amount,
        uint256 timeStamp
    );
}

contract modularMonkeyScam is MonkeyEvents {}

contract MonkeyScam is modularMonkeyScam {
    using SafeMath for *;
    using NameFilter for string;
    using LDKeysCalc for uint256;

    // TODO: check address
    PlayerBookInterface constant private PlayerBook = PlayerBookInterface(0x38A3E0423708f5797284aEDDbac1a69FC0aa3883);

    address private monkeyKing = 0xb75603Fd0B0E55b283DAC9A9ED516A8a9515e3dB;
    address private monkeyQueue = 0x2B215DE0Ec7C1A9b72F48aB357f2E1739487c050;

    string constant public name = "MonkeyScam Round #1";
    string constant public symbol = "MSR";
    uint256 private rndGap_ = 0;

    // TODO: check time
    uint256 constant private rndInit_ = 72 hours;                // round timer starts at this
    uint256 constant private rndInc_ = 30 seconds;              // every full key purchased adds this much to the timer
    uint256 constant private rndMax_ = 72 hours;                // max length a round timer can be
    //==============================================================================
    //     _| _ _|_ _    _ _ _|_    _   .
    //    (_|(_| | (_|  _\(/_ | |_||_)  .  (data used to store game info that changes)
    //=============================|================================================
    uint256 public airDropPot_;             // person who gets the airdrop wins part of this pot
    uint256 public airDropTracker_ = 0;     // incremented each time a "qualified" tx occurs.  used to determine winning air drop
    //****************
    // PLAYER DATA
    //****************
    mapping (address => uint256) public pIDxAddr_;          // (addr => pID) returns player id by address
    mapping (bytes32 => uint256) public pIDxName_;          // (name => pID) returns player id by name
    mapping (uint256 => LDdatasets.Player) public plyr_;   // (pID => data) player data
    mapping (uint256 => LDdatasets.PlayerRounds) public plyrRnds_;    // (pID => rID => data) player round data by player id & round id
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_; // (pID => name => bool) list of names a player owns.  (used so you can change your display name amongst any name you own)
    //****************
    // ROUND DATA
    //****************
    LDdatasets.Round public round_;   // round data
    //****************
    // TEAM FEE DATA
    //****************
    uint256 public fees_ = 40;          // fee distribution
    uint256 public potSplit_ = 20;      // pot split distribution
    //==============================================================================
    //     _ _  _  _|. |`. _  _ _  .
    //    | | |(_)(_||~|~|(/_| _\  .  (these are safety checks)
    //==============================================================================
    /**
     * @dev used to make sure no one can interact with contract until it has
     * been activated.
     */
    modifier isActivated() {
        require(activated_ == true, "its not ready yet");
        _;
    }

    /**
     * @dev prevents contracts from interacting with ratscam
     */
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "non smart contract address only");
        _;
    }

    /**
     * @dev sets boundaries for incoming tx
     */
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "too little money");
        require(_eth <= 100000000000000000000000, "too much money");
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
        LDdatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];

        // buy core
        buyCore(_pID, plyr_[_pID].laff, _eventData_);
    }

    /**
     * @dev converts all incoming ethereum to keys.
     * -functionhash- 0x8f38f309 (using ID for affiliate)
     * -functionhash- 0x98a0871d (using address for affiliate)
     * -functionhash- 0xa65b37a1 (using name for affiliate)
     * @param _affCode the ID/address/name of the player who gets the affiliate fee
     */
    function buyXid(uint256 _affCode)
    isActivated()
    isHuman()
    isWithinLimits(msg.value)
    public
    payable
    {
        // set up our tx event data and determine if player is new or not
        LDdatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        // fetch player id
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

        // buy core
        buyCore(_pID, _affCode, _eventData_);
    }

    function buyXaddr(address _affCode)
    isActivated()
    isHuman()
    isWithinLimits(msg.value)
    public
    payable
    {
        // set up our tx event data and determine if player is new or not
        LDdatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

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

        // buy core
        buyCore(_pID, _affID, _eventData_);
    }

    function buyXname(bytes32 _affCode)
    isActivated()
    isHuman()
    isWithinLimits(msg.value)
    public
    payable
    {
        // set up our tx event data and determine if player is new or not
        LDdatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

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

        // buy core
        buyCore(_pID, _affID, _eventData_);
    }

    /**
     * @dev essentially the same as buy, but instead of you sending ether
     * from your wallet, it uses your unwithdrawn earnings.
     * -functionhash- 0x349cdcac (using ID for affiliate)
     * -functionhash- 0x82bfc739 (using address for affiliate)
     * -functionhash- 0x079ce327 (using name for affiliate)
     * @param _affCode the ID/address/name of the player who gets the affiliate fee
     * @param _eth amount of earnings to use (remainder returned to gen vault)
     */
    function reLoadXid(uint256 _affCode, uint256 _eth)
    isActivated()
    isHuman()
    isWithinLimits(_eth)
    public
    {
        // set up our tx event data
        LDdatasets.EventReturns memory _eventData_;

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

        // reload core
        reLoadCore(_pID, _affCode, _eth, _eventData_);
    }

    function reLoadXaddr(address _affCode, uint256 _eth)
    isActivated()
    isHuman()
    isWithinLimits(_eth)
    public
    {
        // set up our tx event data
        LDdatasets.EventReturns memory _eventData_;

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

        // reload core
        reLoadCore(_pID, _affID, _eth, _eventData_);
    }

    function reLoadXname(bytes32 _affCode, uint256 _eth)
    isActivated()
    isHuman()
    isWithinLimits(_eth)
    public
    {
        // set up our tx event data
        LDdatasets.EventReturns memory _eventData_;

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

        // reload core
        reLoadCore(_pID, _affID, _eth, _eventData_);
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
        // grab time
        uint256 _now = now;

        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // setup temp var for player eth
        uint256 _eth;

        // check to see if round has ended and no one has run round end yet
        if (_now > round_.end && round_.ended == false && round_.plyr != 0)
        {
            // set up our tx event data
            LDdatasets.EventReturns memory _eventData_;

            // end the round (distributes pot)
            round_.ended = true;
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
            emit MonkeyEvents.onWithdrawAndDistribute
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

            // in any other situation
        } else {
            // get their earnings
            _eth = withdrawEarnings(_pID);

            // gib moni
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

            // fire withdraw event
            emit MonkeyEvents.onWithdraw(_pID, msg.sender, plyr_[_pID].name, _eth, _now);
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
    function registerNameXID(string _nameString, uint256 _affCode, bool _all)
    isHuman()
    public
    payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXIDFromDapp.value(_paid)(_addr, _name, _affCode, _all);

        uint256 _pID = pIDxAddr_[_addr];

        // fire event
        emit MonkeyEvents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }

    function registerNameXaddr(string _nameString, address _affCode, bool _all)
    isHuman()
    public
    payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXaddrFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);

        uint256 _pID = pIDxAddr_[_addr];

        // fire event
        emit MonkeyEvents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }

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
        emit MonkeyEvents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
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
        // grab time
        uint256 _now = now;

        // are we in a round?
        if (_now > round_.strt + rndGap_ && (_now <= round_.end || (_now > round_.end && round_.plyr == 0)))
            return ( (round_.keys.add(1000000000000000000)).ethRec(1000000000000000000) );
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
        // grab time
        uint256 _now = now;

        if (_now < round_.end)
            if (_now > round_.strt + rndGap_)
                return( (round_.end).sub(_now) );
            else
                return( (round_.strt + rndGap_).sub(_now));
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
        if (now > round_.end && round_.ended == false && round_.plyr != 0)
        {
            // if player is winner
            if (round_.plyr == _pID)
            {
                return
                (
                (plyr_[_pID].win).add( ((round_.pot).mul(45)) / 100 ),
                (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID).sub(plyrRnds_[_pID].mask)   ),
                plyr_[_pID].aff
                );
                // if player is not the winner
            } else {
                return
                (
                plyr_[_pID].win,
                (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID).sub(plyrRnds_[_pID].mask)  ),
                plyr_[_pID].aff
                );
            }

            // if round is still going on, or round has ended and round end has been ran
        } else {
            return
            (
            plyr_[_pID].win,
            (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID)),
            plyr_[_pID].aff
            );
        }
    }

    /**
     * solidity hates stack limits.  this lets us avoid that hate
     */
    function getPlayerVaultsHelper(uint256 _pID)
    private
    view
    returns(uint256)
    {
        return(  ((((round_.mask).add(((((round_.pot).mul(potSplit_)) / 100).mul(1000000000000000000)) / (round_.keys))).mul(plyrRnds_[_pID].keys)) / 1000000000000000000)  );
    }

    /**
     * @dev returns all current round info needed for front end
     * -functionhash- 0x747dff42
     * @return total keys
     * @return time ends
     * @return time started
     * @return current pot
     * @return current player ID in lead
     * @return current player in leads address
     * @return current player in leads name
     * @return airdrop tracker
     * @return airdrop pot
     */
    function getCurrentRoundInfo()
    public
    view
    returns(uint256, uint256, uint256, uint256, uint256, address, bytes32, uint256, uint256)
    {
        return
        (
        round_.keys,              //0
        round_.end,               //1
        round_.strt,              //2
        round_.pot,               //3
        round_.plyr,              //4
        plyr_[round_.plyr].addr,  //5
        plyr_[round_.plyr].name,  //6
        airDropTracker_,          //7
        airDropPot_               //8
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
        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];

        return
        (
        _pID,                               //0
        plyr_[_pID].name,                   //1
        plyrRnds_[_pID].keys,         //2
        plyr_[_pID].win,                    //3
        (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID)),       //4
        plyr_[_pID].aff,                    //5
        plyrRnds_[_pID].eth           //6
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
    function buyCore(uint256 _pID, uint256 _affID, LDdatasets.EventReturns memory _eventData_)
    private
    {
        // grab time
        uint256 _now = now;

        // if round is active
        if (_now > round_.strt + rndGap_ && (_now <= round_.end || (_now > round_.end && round_.plyr == 0)))
        {
            // call core
            core(_pID, msg.value, _affID, _eventData_);

            // if round is not active
        } else {
            // check to see if end round needs to be ran
            if (_now > round_.end && round_.ended == false)
            {
                // end the round (distributes pot) & start new round
                round_.ended = true;
                _eventData_ = endRound(_eventData_);

                // build event data
                _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
                _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

                // fire buy and distribute event
                emit MonkeyEvents.onBuyAndDistribute
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
    function reLoadCore(uint256 _pID, uint256 _affID, uint256 _eth, LDdatasets.EventReturns memory _eventData_)
    private
    {
        // grab time
        uint256 _now = now;

        // if round is active
        if (_now > round_.strt + rndGap_ && (_now <= round_.end || (_now > round_.end && round_.plyr == 0)))
        {
            // get earnings from all vaults and return unused to gen vault
            // because we use a custom safemath library.  this will throw if player
            // tried to spend more eth than they have.
            plyr_[_pID].gen = withdrawEarnings(_pID).sub(_eth);

            // call core
            core(_pID, _eth, _affID, _eventData_);

            // if round is not active and end round needs to be ran
        } else if (_now > round_.end && round_.ended == false) {
            // end the round (distributes pot) & start new round
            round_.ended = true;
            _eventData_ = endRound(_eventData_);

            // build event data
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

            // fire buy and distribute event
            emit MonkeyEvents.onReLoadAndDistribute
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

    /**
     * @dev this is the core logic for any buy/reload that happens while a round
     * is live.
     */
    function core(uint256 _pID, uint256 _eth, uint256 _affID, LDdatasets.EventReturns memory _eventData_)
    private
    {
        // if player is new to round
        if (plyrRnds_[_pID].keys == 0)
            _eventData_ = managePlayer(_pID, _eventData_);

        // early round eth limiter
        if (round_.eth < 100000000000000000000 && plyrRnds_[_pID].eth.add(_eth) > 10000000000000000000)
        {
            uint256 _availableLimit = (10000000000000000000).sub(plyrRnds_[_pID].eth);
            uint256 _refund = _eth.sub(_availableLimit);
            plyr_[_pID].gen = plyr_[_pID].gen.add(_refund);
            _eth = _availableLimit;
        }

        // if eth left is greater than min eth allowed (sorry no pocket lint)
        if (_eth > 1000000000)
        {

            // mint the new keys
            uint256 _keys = (round_.eth).keysRec(_eth);

            // if they bought at least 1 whole key
            if (_keys >= 1000000000000000000)
            {
                updateTimer(_keys);

                // set new leaders
                if (round_.plyr != _pID)
                    round_.plyr = _pID;

                // set the new leader bool to true
                _eventData_.compressedData = _eventData_.compressedData + 100;
            }

            // manage airdrops
            if (_eth >= 100000000000000000)  // larger 0.1eth
            {
                airDropTracker_++;
                if (airdrop() == true)
                {
                    // gib muni
                    uint256 _prize;
                    if (_eth >= 10000000000000000000)  // larger 10eth
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

                        // let event know a tier 1 prize was won
                        _eventData_.compressedData += 100000000000000000000000000000000;
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
            plyrRnds_[_pID].keys = _keys.add(plyrRnds_[_pID].keys);
            plyrRnds_[_pID].eth = _eth.add(plyrRnds_[_pID].eth);

            // update round
            round_.keys = _keys.add(round_.keys);
            round_.eth = _eth.add(round_.eth);

            // distribute eth
            _eventData_ = distributeExternal(_pID, _eth, _affID, _eventData_);
            _eventData_ = distributeInternal(_pID, _eth, _keys, _eventData_);

            // call end tx function to fire end tx event.
            endTx(_pID, _eth, _keys, _eventData_);
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
    function calcUnMaskedEarnings(uint256 _pID)
    private
    view
    returns(uint256)
    {
        return((((round_.mask).mul(plyrRnds_[_pID].keys)) / (1000000000000000000)).sub(plyrRnds_[_pID].mask));
    }

    /**
     * @dev returns the amount of keys you would get given an amount of eth.
     * -functionhash- 0xce89c80c
     * @param _eth amount of eth sent in
     * @return keys received
     */
    function calcKeysReceived(uint256 _eth)
    public
    view
    returns(uint256)
    {
        // grab time
        uint256 _now = now;

        // are we in a round?
        if (_now > round_.strt + rndGap_ && (_now <= round_.end || (_now > round_.end && round_.plyr == 0)))
            return ( (round_.eth).keysRec(_eth) );
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
        // grab time
        uint256 _now = now;

        // are we in a round?
        if (_now > round_.strt + rndGap_ && (_now <= round_.end || (_now > round_.end && round_.plyr == 0)))
            return ( (round_.keys.add(_keys)).ethRec(_keys) );
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
        require (msg.sender == address(PlayerBook), "only PlayerBook can call this function");
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
        require (msg.sender == address(PlayerBook), "only PlayerBook can call this function");
        if(plyrNames_[_pID][_name] == false)
            plyrNames_[_pID][_name] = true;
    }

    /**
     * @dev gets existing or registers new pID.  use this when a player may be new
     * @return pID
     */
    function determinePID(LDdatasets.EventReturns memory _eventData_)
    private
    returns (LDdatasets.EventReturns)
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        // if player is new to this version of ratscam
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
     * @dev decides if round end needs to be run & new round started.  and if
     * player unmasked earnings from previously played rounds need to be moved.
     */
    function managePlayer(uint256 _pID, LDdatasets.EventReturns memory _eventData_)
    private
    returns (LDdatasets.EventReturns)
    {
        // set the joined round bool to true
        _eventData_.compressedData = _eventData_.compressedData + 10;

        return(_eventData_);
    }

    /**
     * @dev ends the round. manages paying out winner/splitting up pot
     */
    function endRound(LDdatasets.EventReturns memory _eventData_)
    private
    returns (LDdatasets.EventReturns)
    {
        // grab our winning player and team id&#39;s
        uint256 _winPID = round_.plyr;

        // grab our pot amount
        // add airdrop pot into the final pot
        uint256 _pot = round_.pot + airDropPot_;

        // calculate our winner share, community rewards, gen share,
        uint256 _win = (_pot.mul(40)) / 100;
        uint256 _com = (_pot.mul(30)) / 100;
        uint256 _queen = (_pot.mul(10)) / 100;
        uint256 _gen = (_pot.mul(20)) / 100;

        // calculate ppt for round mask
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_.keys);
        uint256 _dust = _gen.sub((_ppt.mul(round_.keys)) / 1000000000000000000);
        if (_dust > 0)
        {
            _gen = _gen.sub(_dust);
            _com = _com.add(_dust);
        }

        // pay our winner
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);

        // community rewards
        if (!address(monkeyKing).call.value(_com)())
        {
            _gen = _gen.add(_com);
            _com = 0;
        }

        if (!address(monkeyQueue).call.value(_queen)())
        {
            _gen = _gen.add(_queen);
            _queen = 0;
        }

        // distribute gen portion to key holders
        round_.mask = _ppt.add(round_.mask);

        // prepare event data
        _eventData_.compressedData = _eventData_.compressedData + (round_.end * 1000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * 100000000000000000000000000);
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.winnerName = plyr_[_winPID].name;
        _eventData_.amountWon = _win;
        _eventData_.genAmount = _gen;
        _eventData_.newPot = 0;

        return(_eventData_);
    }

    /**
     * @dev moves any unmasked earnings to gen vault.  updates earnings mask
     */
    function updateGenVault(uint256 _pID)
    private
    {
        uint256 _earnings = calcUnMaskedEarnings(_pID);
        if (_earnings > 0)
        {
            // put in gen vault
            plyr_[_pID].gen = _earnings.add(plyr_[_pID].gen);
            // zero out their earnings by updating mask
            plyrRnds_[_pID].mask = _earnings.add(plyrRnds_[_pID].mask);
        }
    }

    /**
     * @dev updates round timer based on number of whole keys bought.
     */
    function updateTimer(uint256 _keys)
    private
    {
        // grab time
        uint256 _now = now;

        // calculate time based on number of keys bought
        uint256 _newTime;
        if (_now > round_.end && round_.plyr == 0)
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(_now);
        else
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(round_.end);

        // compare to max and set new end time
        if (_newTime < (rndMax_).add(_now))
            round_.end = _newTime;
        else
            round_.end = rndMax_.add(_now);
    }

    /**
     * @dev generates a random number between 0-99 and checks to see if thats
     * resulted in an airdrop win
     * @return do we have a winner?
     */
    function airdrop()
    private
    view
    returns(bool)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(

                (block.timestamp).add
                (block.difficulty).add
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
                (block.gaslimit).add
                ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
                (block.number)

            )));
        if((seed - ((seed / 1000) * 1000)) < airDropTracker_)
            return(true);
        else
            return(false);
    }

    /**
     * @dev distributes eth based on fees to com, aff, and p3d
     */
    function distributeExternal(uint256 _pID, uint256 _eth, uint256 _affID, LDdatasets.EventReturns memory _eventData_)
    private
    returns(LDdatasets.EventReturns)
    {
        // pay 15% out to community rewards
        uint256 _com = _eth * 15 / 100;

        // distribute share to affiliate 25%
        uint256 _aff = _eth*25 / 100;

        uint256 _toqueen = 0;

        // decide what to do with affiliate share of fees
        // affiliate must not be self, and must have a name registered
        if (_affID != _pID && plyr_[_affID].name != &#39;&#39;) {
            plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
            emit MonkeyEvents.onAffiliatePayout(_affID, plyr_[_affID].addr, plyr_[_affID].name, _pID, _aff, now);
        } else {
            // no affiliates, add to community
            _com += (_aff*80/100);
            _toqueen += (_aff*20/100);
        }

        if (_toqueen > 0) {
            if(!address(monkeyQueue).call.value(_toqueen)()) {
                //do nothing
            }
        }

        if (!address(monkeyKing).call.value(_com)())
        {
            // This ensures Team Just cannot influence the outcome of FoMo3D with
            // bank migrations by breaking outgoing transactions.
            // Something we would never do. But that&#39;s not the point.
            // We spent 2000$ in eth re-deploying just to patch this, we hold the
            // highest belief that everything we create should be trustless.
            // Team JUST, The name you shouldn&#39;t have to trust.
        }

        return(_eventData_);
    }

    /**
     * @dev distributes eth based on fees to gen and pot
     */
    function distributeInternal(uint256 _pID, uint256 _eth, uint256 _keys, LDdatasets.EventReturns memory _eventData_)
    private
    returns(LDdatasets.EventReturns)
    {
        // calculate gen share
        uint256 _gen = (_eth.mul(fees_)) / 100;

        // toss 5% into airdrop pot
        uint256 _air = (_eth / 20);
        airDropPot_ = airDropPot_.add(_air);

        // calculate pot (15%)
        uint256 _pot = (_eth.mul(15) / 100);

        // distribute gen share (thats what updateMasks() does) and adjust
        // balances for dust.
        uint256 _dust = updateMasks(_pID, _gen, _keys);
        if (_dust > 0)
            _gen = _gen.sub(_dust);

        // add eth to pot
        round_.pot = _pot.add(_dust).add(round_.pot);

        // set up event data
        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _pot;

        return(_eventData_);
    }

    /**
     * @dev updates masks for round and player when keys are bought
     * @return dust left over
     */
    function updateMasks(uint256 _pID, uint256 _gen, uint256 _keys)
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
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_.keys);
        round_.mask = _ppt.add(round_.mask);

        // calculate player earning from their own buy (only based on the keys
        // they just bought).  & update player earnings mask
        uint256 _pearn = (_ppt.mul(_keys)) / (1000000000000000000);
        plyrRnds_[_pID].mask = (((round_.mask.mul(_keys)) / (1000000000000000000)).sub(_pearn)).add(plyrRnds_[_pID].mask);

        // calculate & return dust
        return(_gen.sub((_ppt.mul(round_.keys)) / (1000000000000000000)));
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
        updateGenVault(_pID);

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
    function endTx(uint256 _pID, uint256 _eth, uint256 _keys, LDdatasets.EventReturns memory _eventData_)
    private
    {
        _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

        emit MonkeyEvents.onEndTx
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
            _eventData_.genAmount,
            _eventData_.potAmount,
            airDropPot_
        );
    }

    /** upon contract deploy, it will be deactivated.  this is a one time
     * use function that will activate the contract.  we do this so devs
     * have time to set things up on the web end                            **/
    bool public activated_ = false;
    function activate()
    public
    {
        // only owner can activate
        // TODO: set owner
        require(
            msg.sender == 0xb75603Fd0B0E55b283DAC9A9ED516A8a9515e3dB ||
            msg.sender == 0x029800F64f16d81FC164319Edb84cf85bFf15e80,
            "only owner can activate"
        );

        // can only be ran once
        require(activated_ == false, "dogscam already activated");

        // activate the contract
        activated_ = true;

        round_.strt = now - rndGap_;
        round_.end = now + rndInit_;
    }
}

//==============================================================================
//   __|_ _    __|_ _  .
//  _\ | | |_|(_ | _\  .
//==============================================================================
library LDdatasets {
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
        bytes32 name;   // player name
        uint256 win;    // winnings vault
        uint256 gen;    // general vault
        uint256 aff;    // affiliate vault
        uint256 laff;   // last affiliate id used
    }
    struct PlayerRounds {
        uint256 eth;    // eth player has added to round (used for eth limiter)
        uint256 keys;   // keys
        uint256 mask;   // player mask
    }
    struct Round {
        uint256 plyr;   // pID of player in lead
        uint256 end;    // time ends/ended
        bool ended;     // has round end function been ran
        uint256 strt;   // time round started
        uint256 keys;   // keys
        uint256 eth;    // total eth in
        uint256 pot;    // eth to pot (during round) / final amount paid to winner (after round ends)
        uint256 mask;   // global mask
    }
}

//==============================================================================
//  |  _      _ _ | _  .
//  |<(/_\/  (_(_||(_  .
//=======/======================================================================
library LDKeysCalc {
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
}