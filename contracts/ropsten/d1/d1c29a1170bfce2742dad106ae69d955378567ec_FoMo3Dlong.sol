pragma solidity ^0.4.24;

//==============================================================================
//     _    _  _ _|_ _  .
//    (/_\/(/_| | | _\  .
//==============================================================================
contract F3Devents {
    // fired whenever a player registers a name
    // event onNewName
    // (
    //     uint256 indexed playerID,
    //     address indexed playerAddress,
    //     bytes32 indexed playerName,
    //     bool isNewPlayer,
    //     uint256 affiliateID,
    //     address affiliateAddress,
    //     bytes32 affiliateName,
    //     uint256 amountPaid,
    //     uint256 timeStamp
    // );
    
    // fired at end of buy or reload
    // event onEndTx
    // (
    //     uint256 compressedData,     
    //     uint256 compressedIDs,      
    //     bytes32 playerName,
    //     address playerAddress,
    //     uint256 ethIn,
    //     uint256 keysBought,
    //     address winnerAddr,
    //     bytes32 winnerName,
    //     uint256 amountWon,
    //     uint256 newPot,
    //     uint256 jcgAmount,
    //     uint256 genAmount,
    //     uint256 potAmount,
    //     uint256 airDropPot
    // );
    
	// fired whenever theres a withdraw
    event onWithdraw
    (
        uint256 indexed playerID,
        address playerAddress,
        // bytes32 playerName,
        uint256 ethOut,
        uint256 timeStamp
    );
    
    // fired whenever a withdraw forces end round to be ran
    event onWithdrawAndDistribute
    (
        address playerAddress,
        // bytes32 playerName,
        uint256 ethOut,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        // bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 jcgAmount,
        uint256 genAmount
    );
    
    // (fomo3d long only) fired whenever a player tries a buy after round timer 
    // hit zero, and causes end round to be ran.
    event onBuyAndDistribute
    (
        address playerAddress,
        // bytes32 playerName,
        uint256 ethIn,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        // bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 jcgAmount,
        uint256 genAmount
    );
    
    // (fomo3d long only) fired whenever a player tries a reload after round timer 
    // hit zero, and causes end round to be ran.
    event onReLoadAndDistribute
    (
        address playerAddress,
        // bytes32 playerName,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        // bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 jcgAmount,
        uint256 genAmount
    );
    
    // fired whenever an affiliate is paid
    event onAffiliatePayout
    (
        uint256 indexed affiliateID,
        address affiliateAddress,
        // bytes32 affiliateName,
        uint256 indexed roundID,
        uint256 indexed buyerID,
        uint256 amount,
        uint256 timeStamp
    );
    
    // // received pot swap deposit
    // event onPotSwapDeposit
    // (
    //     uint256 roundID,
    //     uint256 amountAddedToPot
    // );
}

//==============================================================================
//   _ _  _ _|_ _ _  __|_   _ _ _|_    _   .
//  (_(_)| | | | (_|(_ |   _\(/_ | |_||_)  .
//====================================|=========================================

contract modularLong is F3Devents {}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
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
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
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

contract FoMo3Dlong is Pausable  {
    using SafeMath for *;
    // using NameFilter for string;
    using F3DKeysCalcLong for uint256;
	
	// otherFoMo3D private otherF3D_;
    // DiviesInterface constant private Divies = DiviesInterface(0xc7029Ed9EBa97A096e72607f4340c34049C7AF48);
    // JIincForwarderInterface constant private Jekyll_Island_Inc = JIincForwarderInterface(0xdd4950F977EE28D2C132f1353D1595035Db444EE);
	// PlayerBookInterface constant private PlayerBook = PlayerBookInterface(0xD60d353610D9a5Ca478769D371b53CEfAA7B6E4c);
    // F3DexternalSettingsInterface constant private extSettings = F3DexternalSettingsInterface(0x32967D6c142c2F38AB39235994e2DDF11c37d590);

    address private constant WALLET_ETH_COM   = 0xAba33f3a098f7f0AC9B60614e395A40406e97915; 
    address private constant WALLET_ETH_ADMIN = 0xAba33f3a098f7f0AC9B60614e395A40406e97915; 
//==============================================================================
//     _ _  _  |`. _     _ _ |_ | _  _  .
//    (_(_)| |~|~|(_||_|| (_||_)|(/__\  .  (game settings)
//=================_|===========================================================
    string constant public name = "FoMo3D Long Official";
    string constant public symbol = "F3D";
	// uint256 private rndExtra_ = extSettings.getLongExtra();     // length of the very first ICO 
    // uint256 private rndGap_ = extSettings.getLongGap();         // length of ICO phase, set to 1 year for EOS.
    uint256 constant private rndInit_ = 24 hours;                // round timer starts at this
    uint256 constant private rndInc_ = 30 seconds;              // every full key purchased adds this much to the timer
    uint256 constant private rndMax_ = 24 hours;                // max length a round timer can be
//==============================================================================
//     _| _ _|_ _    _ _ _|_    _   .
//    (_|(_| | (_|  _\(/_ | |_||_)  .  (data used to store game info that changes)
//=============================|================================================
    uint256 public contractStartDate_;    // contract creation time
    mapping (uint256 => uint256) public playerOrders_; // buyers in order => pID
    uint256 public plyrCnt_; // player count
//****************
// AIRDROP DATA 
//****************
	uint256 public airDropPot_;             // person who gets the airdrop wins part of this pot
    uint256 public airDropTracker_ = 0;     // incremented each time a "qualified" tx occurs.  used to determine winning air drop
//****************
// LEEKSTEAL DATA 
//****************
    uint256 public leekStealPot_;             // person who gets the first leeksteal wins part of this pot
    uint256 public leekStealTracker_ = 0;     // incremented each time a "qualified" tx occurs.  used to determine winning leek steal
    uint256 public leekStealToday_;
    bool public leekStealOn_;
//****************
// PLAYER DATA 
//****************
    uint256 public pID_;        // total number of players
    mapping (address => uint256) public pIDxAddr_;          // (addr => pID) returns player id by address
    // mapping (bytes32 => uint256) public pIDxName_;          // (name => pID) returns player id by name
    mapping (uint256 => F3Ddatasets.Player) public plyr_;   // (pID => data) player data
    mapping (uint256 => mapping (uint256 => F3Ddatasets.PlayerRounds)) public plyrRnds_;    // (pID => rID => data) player round data by player id & round id
    mapping (uint256 => mapping (uint256 => F3Ddatasets.PlayerPhrases)) public plyrPhas_;    // (pID => phraseID => data) player round data by player id & round id
    // mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_; // (pID => name => bool) list of names a player owns.  (used so you can change your display name amongst any name you own)
//****************
// ROUND DATA 
//****************
    uint256 public rID_;    // round id number / total rounds that have happened
    mapping (uint256 => F3Ddatasets.Round) public round_;   // (rID => data) round data
    mapping (uint256 => uint256) public rndEth_;      // (rID => data) eth in by round id
//****************
// PHRASE DATA 
//****************
    uint256 public phID_; // gu phrase ID
    mapping (uint256 => F3Ddatasets.Phrase) public phrase_;   // (phID_ => data) round data
//****************
// FEE DATA 
//****************
    F3Ddatasets.Fee public fees_;          // fee distribution
    F3Ddatasets.PotSplit public potSplit_;     // pot split distribution
//****************
// WHITELIST
//****************
    mapping(uint256 => bool) public whitelisted_Prebuy; // pID => isWhitelisted

//==============================================================================
//     _ _  _  __|_ _    __|_ _  _  .
//    (_(_)| |_\ | | |_|(_ | (_)|   .  (initial data setup upon contract deploy)
//==============================================================================
    constructor()
        public
    {
        // (F3D, jcg) + (Pot , Referrals, Community)
            // Referrals / Community rewards are mathematically designed to come from the winner&#39;s share of the pot.
        fees_ = F3Ddatasets.Fee(30,20);  //20% to pot, 10% to aff(8% + 2%), 5% 偷韮菜, 2% to com, 13% to air drop pot
        
        // how to split up the final pot
        potSplit_ = F3Ddatasets.PotSplit(15,10);  

        contractStartDate_ = now;

        pID_++; // grab their player ID and last aff ID, from player names contract 
        pIDxAddr_[msg.sender] = pID_; // set up admin player account 
        plyr_[pID_].addr = msg.sender; // set up admin player account 

        plyrCnt_++;
        playerOrders_[plyrCnt_] = pID_; // for recording the 500 winners
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
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;    
    }
    
//==============================================================================
//     _    |_ |. _   |`    _  __|_. _  _  _  .
//    |_)|_||_)||(_  ~|~|_|| |(_ | |(_)| |_\  .  (use these to interact with contract)
//====|=========================================================================
    /**
     * @dev emergency buy uses last stored affiliate ID
     */
    function()
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        // determine if player is new or not
        uint256 _pID = pIDxAddr_[msg.sender];
        if (_pID == 0)
        {
            pID_++; // grab their player ID and last aff ID, from player names contract 
            pIDxAddr_[msg.sender] = pID_; // set up player account 
            plyr_[pID_].addr = msg.sender; // set up player account 
        } 
        
        // buy core 
        buyCore(_pID, plyr_[_pID].laff);
    }
 
    function buyXid(uint256 _affID)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        // determine if player is new or not
        uint256 _pID = pIDxAddr_[msg.sender]; // fetch player id
        if (_pID == 0)
        {
            pID_++; // grab their player ID and last aff ID, from player names contract 
            pIDxAddr_[msg.sender] = pID_; // set up player account 
            plyr_[pID_].addr = msg.sender; // set up player account 
        } 
        
        // manage affiliate residuals
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affID == 0 || _affID == _pID)
        {
            _affID = plyr_[_pID].laff; // use last stored affiliate code 
            
        // if affiliate code was given & its not the same as previously stored 
        } else if (_affID != plyr_[_pID].laff) {
            // update last affiliate 
            plyr_[_pID].laff = _affID;
        }

        // buy core 
        buyCore(_pID, _affID);
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
            // F3Ddatasets.EventReturns memory _eventData_;
            
            // end the round (distributes pot)
			round_[_rID].ended = true;
            endRound();
            
			// get their earnings
            _eth = withdrawEarnings(_pID);
            
            // gib moni
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);    
            
            // // build event data
            // _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            // _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;
            
            // fire withdraw and distribute event
            // emit F3Devents.onWithdrawAndDistribute();
            
        // in any other situation
        } else {
            // get their earnings
            _eth = withdrawEarnings(_pID);
            
            // gib moni
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);
            
            // fire withdraw event
            // emit F3Devents.onWithdraw(_pID, msg.sender, _eth, _now);
        }
    }

    function updateWhitelist(uint256[] _pIDs, bool _isWhitelisted)
        public
        onlyOwner
    {
        for (uint i = 0; i < _pIDs.length; i++) {
            whitelisted_Prebuy[_pIDs[i]] = _isWhitelisted;
        }
    }

    function safeDrain() 
        public
        onlyOwner
    {
        WALLET_ETH_ADMIN.transfer(this.balance);
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
    // function getBuyPrice()
    //     public 
    //     view 
    //     returns(uint256)
    // {  
    //     // setup local rID
    //     uint256 _rID = rID_;
        
    //     // grab time
    //     uint256 _now = now;
        
    //     // are we in a round?
    //     if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
    //         return ( (round_[_rID].keys.add(1000000000000000000)).ethRec(1000000000000000000) );
    //     else // rounds over.  need price for new round
    //         return ( 75000000000000 ); // init
    // }
    
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
            if (_now > round_[_rID].strt)
                return( (round_[_rID].end).sub(_now) );
            else
                return( (round_[_rID].strt).sub(_now) );
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
                    (plyr_[_pID].win).add( ((round_[_rID].pot).mul(48)) / 100 ),
                    //(plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)   ),
                    (plyr_[_pID].gen).add(calcUnMaskedKeyEarnings(_pID, plyr_[_pID].lrnd)).add(plyr_[_pID].genGu).add(calcUnMaskedGuEarnings(_pID, plyr_[_pID].lrnd)),
                    plyr_[_pID].aff
                );
            // if player is not the winner
            } else {
                return
                (
                    plyr_[_pID].win,
                    //(plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)  ),
                    (plyr_[_pID].gen).add(calcUnMaskedKeyEarnings(_pID, plyr_[_pID].lrnd)).add(plyr_[_pID].genGu).add(calcUnMaskedGuEarnings(_pID, plyr_[_pID].lrnd)),
                    plyr_[_pID].aff
                );
            }
            
        // if round is still going on, or round has ended and round end has been ran
        } else {
            return
            (
                plyr_[_pID].win,
                (plyr_[_pID].gen).add(calcUnMaskedKeyEarnings(_pID, plyr_[_pID].lrnd)).add(plyr_[_pID].genGu).add(calcUnMaskedGuEarnings(_pID, plyr_[_pID].lrnd)),
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
        return(  ((((round_[_rID].maskKey).add(((((round_[_rID].pot).mul(potSplit_.gen)) / 100).mul(1000000000000000000)) / (round_[_rID].keys))).mul(plyrRnds_[_pID][_rID].keys)) / 1000000000000000000)  );
    }
    
    /**
     * @dev returns all current round info needed for front end
     * -functionhash- 0x747dff42
     * @return round id 
     * @return total keys for round 
     * @return total gu for round 
     * @return time round ends
     * @return time round started
     * @return current pot 
     * @return player ID in lead 
     * @return current player in leads address
     * @return eth in for round
     * @return airdrop tracker # & airdrop pot
     */
    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, uint256, uint256)
    {
        // setup local rID
        uint256 _rID = rID_;
        
        return
        (
            _rID,                           //0
            round_[_rID].keys,              //1
            round_[_rID].gu,                //2
            round_[_rID].end,               //3
            round_[_rID].strt,              //4
            round_[_rID].pot,               //5
            round_[_rID].plyr,              //6
            plyr_[round_[_rID].plyr].addr,  //7
            rndEth_[_rID],                  //8
            airDropTracker_ + (airDropPot_ * 1000)   //9
        );
    }

    /**
     * @dev returns player info based on address.  if no address is given, it will 
     * use msg.sender 
     * -functionhash- 0xee0b5d8b
     * @param _addr address of the player you want to lookup 
     * @return player ID 
     * @return keys owned (current round)
     * @return gu owned (current round)
     * @return winnings vault
     * @return general vault 
     * @return affiliate vault 
	 * @return player round eth
     */
    function getPlayerInfoByAddress(address _addr)
        public 
        view 
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256)
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
            plyrRnds_[_pID][_rID].keys,         //1
            plyrRnds_[_pID][_rID].gu,           //2
            plyr_[_pID].win,                    //3
            (plyr_[_pID].gen).add(calcUnMaskedKeyEarnings(_pID, plyr_[_pID].lrnd)).add(plyr_[_pID].genGu).add(calcUnMaskedGuEarnings(_pID, plyr_[_pID].lrnd)), //4
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
    function buyCore(uint256 _pID, uint256 _affID)
        whenNotPaused
        private
    {
        // setup local rID
        uint256 _rID = rID_;
        
        // grab time
        uint256 _now = now;

        // whitelist checking
        if (_now < round_[rID_].strt + 3 days) {
            require(whitelisted_Prebuy[_pID] || whitelisted_Prebuy[_affID]);
        }
        
        // if round is active
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) 
        {
            // call core 
            core(_rID, _pID, msg.value, _affID);
        
        // if round is not active     
        } else {
            // check to see if end round needs to be ran
            if (_now > round_[_rID].end && round_[_rID].ended == false) 
            {
                // end the round (distributes pot) & start new round
			    round_[_rID].ended = true;
                endRound();
            }
            
            // put eth in players vault 
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }
    
    /**
     * @dev this is the core logic for any buy/reload that happens while a round 
     * is live.
     */
    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID)
        private
    {
        // if player is new to current round
        if (plyrRnds_[_pID][_rID].keys == 0)
        {
            // if player has played a previous round, move their unmasked earnings
            // from that round to gen vault.
            if (plyr_[_pID].lrnd != 0)
                updateGenVault(_pID, plyr_[_pID].lrnd);
            
            plyr_[_pID].lrnd = rID_; // update player&#39;s last round played
        }
        
        // early round eth limiter (0-100 eth)
        uint256 _availableLimit;
        uint256 _refund;
        if (round_[_rID].eth < 1e20 && plyrRnds_[_pID][_rID].eth.add(_eth) > 2e18)
        {
            _availableLimit = (2e18).sub(plyrRnds_[_pID][_rID].eth);
            _refund = _eth.sub(_availableLimit);
            plyr_[_pID].gen = plyr_[_pID].gen.add(_refund);
            _eth = _availableLimit;
        } else if (round_[_rID].eth < 5e20 && plyrRnds_[_pID][_rID].eth.add(_eth) > 5e18)
        {
            _availableLimit = (5e18).sub(plyrRnds_[_pID][_rID].eth);
            _refund = _eth.sub(_availableLimit);
            plyr_[_pID].gen = plyr_[_pID].gen.add(_refund);
            _eth = _availableLimit;
        }
        
        // if eth left is greater than min eth allowed (sorry no pocket lint)
        if (_eth > 1e9) 
        {
            // mint the new keys
            uint256 _keys = (round_[_rID].eth).keysRec(_eth);
            
            // if they bought at least 1 whole key
            if (_keys >= 1e18)
            {
                updateTimer(_keys, _rID);

                // set new leaders
                if (round_[_rID].plyr != _pID)
                    round_[_rID].plyr = _pID;
            }
            
            // manage airdrops
            if (_eth >= 1e17)
            {
                airDropTracker_++;
                if (airdrop() == true)
                {
                    // gib muni
                    uint256 _prize;
                    if (_eth >= 1e19)
                    {
                        // calculate prize and give it to winner
                        _prize = ((airDropPot_).mul(75)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);
                        
                        // adjust airDropPot 
                        airDropPot_ = (airDropPot_).sub(_prize);
                        
                        // let event know a tier 3 prize was won 
                    } else if (_eth >= 1e18 && _eth < 1e19) {
                        // calculate prize and give it to winner
                        _prize = ((airDropPot_).mul(50)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);
                        
                        // adjust airDropPot 
                        airDropPot_ = (airDropPot_).sub(_prize);
                        
                        // let event know a tier 2 prize was won 
                    } else if (_eth >= 1e17 && _eth < 1e18) {
                        // calculate prize and give it to winner
                        _prize = ((airDropPot_).mul(25)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);
                        
                        // adjust airDropPot 
                        airDropPot_ = (airDropPot_).sub(_prize);
                        
                        // let event know a tier 3 prize was won 
                    }

                    // reset air drop tracker
                    airDropTracker_ = 0;
                }
            }   
            
            leekStealGo();

            // update player 
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);
            plyrCnt_++;
            playerOrders_[plyrCnt_] = pID_; // for recording the 500 winners
            
            // update round
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = _eth.add(round_[_rID].eth);
            rndEth_[_rID] = _eth.add(rndEth_[_rID]);
    
            // distribute eth
            distributeExternal(_rID, _pID, _eth, _affID);
            distributeInternal(_rID, _pID, _eth, _keys);

            // manage gu-referral
            updateGuReferral(_pID, _affID, _eth);
            
            // call end tx function to fire end tx event.
		    // endTx(_pID, _eth, _keys);
        }
    }


    // * gu-referral not depends on round, depends on the contract 
    uint256 public minEthRequired_;       // got update in updateGuPhrase()
    uint256 public guPoolAllocation_;     // got update in updateGuPhrase()
    // uint256 public mapping (uint256 => uint256) guDistributed_; // phrase ID => distributed gu
    // uint256 public phMask_;

    function updateGuReferral(uint256 _pID, uint256 _affID, uint256 _eth) private {
        uint256 _newPhID = updateGuPhrase();

        // update phrase, and distribute remaining gu for the last phrase
        if (phID_ < _newPhID) {
            uint256 _remainGu = guPoolAllocation_ - phrase_[phID_].guGiven;
            if (_remainGu > 0) updateReferralMasks(phID_, _remainGu);
            phID_ = _newPhID; // update the phrase ID
            plyr_[1].gu = (guPoolAllocation_ / 5).add(plyr_[1].gu); // give gu to com
            phrase_[_newPhID].guGiven = (guPoolAllocation_ / 5).add(phrase_[_newPhID].guGiven);
        }

        // update referral eth on affiliate
        if (_affID != 0 && _affID != _pID) {
            plyrPhas_[_affID][_newPhID].eth = _eth.add(plyrPhas_[_affID][_newPhID].eth);
            phrase_[_newPhID].eth = _eth.add(phrase_[_newPhID].eth);
        }
            
        uint256 _remainGuReward = guPoolAllocation_ - phrase_[_newPhID].guGiven;
        // if 1) one has referral amt larger than requirement, 2) has remaining => then distribute certain amt of Gu, i.e. update gu instead of adding gu
        if (plyrPhas_[_affID][_newPhID].eth >= minEthRequired_ && _remainGuReward >= 1e18) {


            // check if need to reward more gu
            uint256 _totalReward = plyrPhas_[_affID][_newPhID].eth / minEthRequired_;
            uint256 _rewarded = plyrPhas_[_affID][_newPhID].guRewarded;
            uint256 _toReward = _totalReward - _rewarded;
            if (_remainGuReward < _toReward) _toReward =  _remainGuReward;

            // give out gu reward
            plyr_[_affID].gu = _toReward.add(plyr_[_affID].gu); // give gu to player
            plyrPhas_[_affID][_newPhID].guRewarded = _toReward;
            phrase_[_newPhID].guGiven = 1e18.add(phrase_[_newPhID].guGiven);
        }
    }

    function updateReferralMasks(uint256 _phID, uint256 _remainGu) private {
        // remaining gu per total ethIn in the phrase
        uint256 _gpe = (_remainGu.mul(1e18)) / phrase_[_phID].eth; 
        phrase_[_phID].mask = _gpe.add(phrase_[_phID].mask);
    }
    
    function updateGuPhrase()
        private
        returns (uint256) // return phraseNum
    {
        if (now <= contractStartDate_ + 5 days) {
            minEthRequired_ = 5e18;
            guPoolAllocation_ = 100e18;
            return 1; 
        }
        if (now <= contractStartDate_ + 7 days) {
            minEthRequired_ = 4e18;
            guPoolAllocation_ = 200e18;
            return 2; 
        }
        if (now <= contractStartDate_ + 9 days) {
            minEthRequired_ = 3e18;
            guPoolAllocation_ = 400e18;
            return 3; 
        }
        if (now <= contractStartDate_ + 11 days) {
            minEthRequired_ = 2e18;
            guPoolAllocation_ = 800e18;
            return 4; 
        }
        if (now <= contractStartDate_ + 13 days) {
            minEthRequired_ = 1e18;
            guPoolAllocation_ = 1600e18;
            return 5; 
        }
        if (now <= contractStartDate_ + 15 days) {
            minEthRequired_ = 1e18;
            guPoolAllocation_ = 3200e18;
            return 6; 
        }
        if (now <= contractStartDate_ + 17 days) {
            minEthRequired_ = 1e18;
            guPoolAllocation_ = 6400e18;
            return 7; 
        }
        if (now <= contractStartDate_ + 19 days) {
            minEthRequired_ = 1e18;
            guPoolAllocation_ = 12800e18;
            return 8; 
        }
        if (now <= contractStartDate_ + 21 days) {
            minEthRequired_ = 1e18;
            guPoolAllocation_ = 25600e18;
            return 9; 
        }
        if (now <= contractStartDate_ + 23 days) {
            minEthRequired_ = 1e18;
            guPoolAllocation_ = 51200e18;
            return 10; 
        }
        minEthRequired_ = 1e18;
        guPoolAllocation_ = 0;
        return 11;
    }

    mapping (uint256 => uint256) public dayStealTime_; // dayNum => time that makes leekSteal available

    function leekStealGo() private {
        // * check if available and turn on the switch *
        // logic: if now > startday + counter, update var to today as the mapping&#39;s key
        // if today&#39;s value is empty, meaning today game hasnt started, then can set it open if the random number passes
        // --------------------------
        
        // get a number for today dayNum 
        uint leekStealToday_ = (now.sub(round_[rID_].strt) / 1 days); // ** 
        if (dayStealTime_[leekStealToday_] == 0) // if there hasn&#39;t a winner today, proceed
        {
            leekStealTracker_++;
            if (randomNum(leekStealTracker_) == true)
            {
                dayStealTime_[leekStealToday_] = now;
                leekStealOn_ = true;
            }
        }
    }

    function stealTheLeek() public {
        if (leekStealOn_)
        {   
            if (now - dayStealTime_[leekStealToday_] > 300) // if time passed 5min, turn off and exit
            {
                leekStealOn_ = false;
            } else {   
                // if yes then assign the 1eth, if the pool has 1eth
                uint256 _pID = pIDxAddr_[msg.sender]; // fetch player ID
                plyr_[_pID].gen = plyr_[_pID].gen.add(1e18);
            }
        }
    }
//==============================================================================
//     _ _ | _   | _ _|_ _  _ _  .
//    (_(_||(_|_||(_| | (_)| _\  .
//==============================================================================
    /**
     * @dev calculates unmasked earnings for key (just calculates, does not update mask)
     * @return earnings in wei format
     */
    function calcUnMaskedKeyEarnings(uint256 _pID, uint256 _rIDlast)
        private
        view
        returns(uint256)
    {
        return(  (((round_[_rIDlast].maskKey).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1e18)).sub(plyrRnds_[_pID][_rIDlast].maskKey)  );
    }

    /**
     * @dev calculates unmasked earnings for gu (just calculates, does not update mask)
     * @return earnings in wei format
     */
    function calcUnMaskedGuEarnings(uint256 _pID, uint256 _rIDlast)
        private
        view
        returns(uint256)
    {
        return(  (((round_[_rIDlast].maskGu).mul(plyrRnds_[_pID][_rIDlast].gu)) / (1e18)).sub(plyrRnds_[_pID][_rIDlast].maskGu)  );
    }
    
    // /** 
    //  * @dev returns the amount of keys you would get given an amount of eth. 
    //  * -functionhash- 0xce89c80c
    //  * @param _rID round ID you want price for
    //  * @param _eth amount of eth sent in 
    //  * @return keys received 
    //  */
    // function calcKeysReceived(uint256 _rID, uint256 _eth)
    //     public
    //     view
    //     returns(uint256)
    // {
    //     // grab time
    //     uint256 _now = now;
        
    //     // are we in a round?
    //     if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
    //         return ( (round_[_rID].eth).keysRec(_eth) );
    //     else // rounds over.  need keys for new round
    //         return ( (_eth).keys() );
    // }
    
    /** 
     * @dev returns current eth price for X keys.  
     * -functionhash- 0xcf808000
     * @param _keys number of keys desired (in 18 decimal format)
     * @return amount of eth needed to send
     */
    // function iWantXKeys(uint256 _keys)
    //     public
    //     view
    //     returns(uint256)
    // {
    //     // setup local rID
    //     uint256 _rID = rID_;
        
    //     // grab time
    //     uint256 _now = now;
        
    //     // are we in a round?
    //     if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
    //         return ( (round_[_rID].keys.add(_keys)).ethRec(_keys) );
    //     else // rounds over.  need price for new round
    //         return ( (_keys).eth() );
    // }
    /**
     * @dev ends the round. manages paying out winner/splitting up pot
     */
    function endRound()
        private
    {
        // setup local rID
        uint256 _rID = rID_;
        
        // grab our winning player id
        uint256 _winPID = round_[_rID].plyr;
        
        // grab our pot amount
        uint256 _pot = round_[_rID].pot;
        
        // calculate our winner share, community rewards, gen share, 
        // jcg share, and amount reserved for next pot 
        uint256 _win = (_pot.mul(40)) / 100;
        // uint256 _com = (_pot / 50);
        // uint256 _gen = (_pot.mul(potSplit_.gen)) / 100;
        // uint256 _jcg = (_pot.mul(potSplit_.jcg)) / 100;
        // uint256 _res = (((_pot.sub(_win)).sub(_com)).sub(_gen)).sub(_jcg);
        uint256 _res = (_pot.mul(10)) / 100;

        // community rewards
        // if (!address(Jekyll_Island_Inc).call.value(_com)(bytes4(keccak256("deposit()"))))
        // {
        //     // This ensures Team Just cannot influence the outcome of FoMo3D with
        //     // bank migrations by breaking outgoing transactions.
        //     // Something we would never do. But that&#39;s not the point.
        //     // We spent 2000$ in eth re-deploying just to patch this, we hold the 
        //     // highest belief that everything we create should be trustless.
        //     // Team JUST, The name you shouldn&#39;t have to trust.
        //     _jcg = _jcg.add(_com);
        //     _com = 0;
        // }

        // calculate ppt for round mask key
        // uint256 _ppt = (_gen.mul(1e18)) / (round_[_rID].keys);
        // uint256 _dustKey = _gen.sub((_ppt.mul(round_[_rID].keys)) / 1e18);
        // if (_dustKey > 0)
        // {
        //     _gen = _gen.sub(_dustKey);
        //     _res = _res.add(_dustKey);
        // }

        // calculate ppg for round mask gu
        // uint256 _ppg = (_jcg.mul(1e18)) / (round_[_rID].gu);
        // uint256 _dustGu = _jcg.sub((_ppg.mul(round_[_rID].gu)) / 1e18);
        // if (_dustGu > 0)
        // {
        //     _jcg = _jcg.sub(_dustGu);
        //     _res = _res.add(_dustGu);
        // }
        
        // pay our winner
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);

        // pay the rest of the 500 winners
        pay500Winners(_pot);
        
        // distribute gen portion to key holders, and jcg portion to gu-holders
        // round_[_rID].mask = round_[_rID].mask.add(_ppt).add(_ppg);
        
        // // send share for jcg to divies
        // if (_jcg > 0)
        //     Divies.deposit.value(_jcg)();
            
        // prepare event data
        // _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
        // _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * 100000000000000000000000000) + (_winTID * 100000000000000000);
        // _eventData_.winnerAddr = plyr_[_winPID].addr;
        // _eventData_.winnerName = plyr_[_winPID].name;
        // _eventData_.amountWon = _win;
        // _eventData_.genAmount = _gen;
        // _eventData_.jcgAmount = _jcg;
        // _eventData_.newPot = _res;
        
        // start next round
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_);
        round_[_rID].pot = _res;
        
        // return(_eventData_);
    }

    function pay500Winners(uint256 _pot) private {
        // pay the 2-10th
        uint256 _win2 = _pot.mul(25).div(100).div(9);
        for (uint256 i = (plyrCnt_ - 9); i <= (plyrCnt_ - 1); i++) 
            plyr_[playerOrders_[i]].win = _win2.add(plyr_[playerOrders_[i]].win);

        // pay the 11-100th
        uint256 _win3 = _pot.mul(15).div(100).div(90);
        for (uint256 j = (plyrCnt_ - 99); j <= (plyrCnt_ - 10); j++) 
            plyr_[playerOrders_[j]].win = _win3.add(plyr_[playerOrders_[j]].win);

        // pay the 101-500th
        uint256 _win4 = _pot.mul(10).div(100).div(400);
        for (uint256 k = (plyrCnt_ - 499); k <= (plyrCnt_ - 100); k++) 
            plyr_[playerOrders_[k]].win = _win4.add(plyr_[playerOrders_[k]].win);
    }
    
    /**
     * @dev moves any unmasked earnings to gen vault.  updates earnings mask
     */
    function updateGenVault(uint256 _pID, uint256 _rIDlast)
        private 
    {
        uint256 _earnings = calcUnMaskedKeyEarnings(_pID, _rIDlast);
        if (_earnings > 0)
        {
            // put in gen vault
            plyr_[_pID].gen = _earnings.add(plyr_[_pID].gen);
            // zero out their earnings by updating mask
            plyrRnds_[_pID][_rIDlast].maskKey = _earnings.add(plyrRnds_[_pID][_rIDlast].maskKey);
        }
    }

    function updateGenGuVault(uint256 _pID, uint256 _rIDlast)
        private 
    {
        uint256 _earnings = calcUnMaskedGuEarnings(_pID, _rIDlast);
        if (_earnings > 0)
        {
            // put in gen vault
            plyr_[_pID].genGu = _earnings.add(plyr_[_pID].genGu);
            // zero out their earnings by updating mask
            plyrRnds_[_pID][_rIDlast].maskGu = _earnings.add(plyrRnds_[_pID][_rIDlast].maskGu);
        }
    }

    function updateReferralGu(uint256 _pID)
        private 
    {
        // get current phID
        uint256 _phID = phID_;

        // get last claimed phID till
        uint256 _lastClaimedPhID = plyrPhas_[_pID][_phID].lastClaimedPhID;

        // calculate the gu Shares using these two input
        uint256 _guShares;
        for (uint i = (_lastClaimedPhID + 1); i < _phID; i++) {
            _guShares = (phrase_[i].mask.mul(plyrPhas_[_pID][i].eth)).add(_guShares);
            plyrPhas_[_pID][i].lastClaimedPhID = _lastClaimedPhID;
        }

        // then put into player&#39;s gu 
        if (_guShares > 0) {
            plyr_[_pID].gu = _guShares.add(plyr_[_pID].gu);       
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

    function randomNum(uint256 _tracker)
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
        if((seed - ((seed / 1000) * 1000)) < _tracker)
            return(true);
        else
            return(false);
    }

    /**
     * @dev distributes eth based on fees to com, aff, and jcg
     */
    function distributeExternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID)
        private
    {
        // pay 2% out to community rewards
        uint256 _com = _eth / 50;
        uint256 _jcg;
        address(WALLET_ETH_COM).transfer(_com);
        
        // distribute 10% share to affiliate (8% + 2%)
        uint256 _aff = _eth / 10;
        
        // check: affiliate must not be self, and must have an ID
        if (_affID != _pID && _affID != 0) {
            plyr_[_affID].aff = (_aff.mul(8)/10).add(plyr_[_affID].aff); // distribute 8% to 1st aff

            uint256 _affID2 =  plyr_[_affID].laff; // get 2nd aff
            if (_affID2 != _pID && _affID2 != 0) 
                plyr_[_affID2].aff = (_aff.mul(2)/10).add(plyr_[_affID2].aff); // distribute 2% to 2nd aff

            // emit F3Devents.onAffiliatePayout(_affID, plyr_[_affID].addr, plyr_[_affID].name, _rID, _pID, _aff, now);
        } else {
            _jcg = _aff;
        }
    }
    
    /**
     * @dev distributes eth based on fees to gen and pot
     */
    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _keys)
        private
    {
        // calculate gen share
        uint256 _gen = (_eth.mul(fees_.gen)) / 100; // 40%

        // calculate jcg share
        uint256 _jcg = (_eth.mul(fees_.jcg)) / 100; // 20%
        
        // toss 3% into airdrop pot 
        uint256 _air = (_eth.mul(3)) / 100;
        airDropPot_ = airDropPot_.add(_air);

        // toss 5% into leeksteal pot 
        uint256 _steal = (_eth / 20);
        leekStealPot_ = leekStealPot_.add(_steal);
        
        // update eth balance (eth = eth - (2% com share + 3% airdrop + 5% leekSteal + 10% aff share))
        _eth = _eth.sub(((_eth.mul(20)) / 100)); // ** 
        
        // calculate pot 
        uint256 _pot = _eth.sub(_gen).sub(_jcg);
        
        // distribute gen n jcg share (thats what updateMasks() does) and adjust
        // balances for dust.
        uint256 _dustKey = updateKeyMasks(_rID, _pID, _gen, _keys);
        uint256 _dustGu = updateGuMasks(_rID, _pID, _jcg);
        if (_dustKey > 0)
            _gen = _gen.sub(_dustKey);
        if (_dustGu > 0)
            _jcg = _jcg.sub(_dustGu);
        
        // add eth to pot
        round_[_rID].pot = _pot.add(_dustKey).add(_dustGu).add(round_[_rID].pot);
    }

    /**
     * @dev updates masks for round and player when keys are bought
     * @return dust left over 
     */
    function updateKeyMasks(uint256 _rID, uint256 _pID, uint256 _gen, uint256 _keys)
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
        uint256 _ppt = (_gen.mul(1e18)) / (round_[_rID].keys);
        round_[_rID].maskKey = _ppt.add(round_[_rID].maskKey);
            
        // calculate player earning from their own buy (only based on the keys
        // they just bought).  & update player earnings mask
        uint256 _pearn = (_ppt.mul(_keys)) / (1e18);
        plyrRnds_[_pID][_rID].maskKey = (((round_[_rID].maskKey.mul(_keys)) / (1e18)).sub(_pearn)).add(plyrRnds_[_pID][_rID].maskKey);
        
        // calculate & return dust
        return(_gen.sub((_ppt.mul(round_[_rID].keys)) / (1e18)));
    }

    /**
     * @dev updates gu masks for round and player
     * @return dust left over 
     */
    function updateGuMasks(uint256 _rID, uint256 _pID, uint256 _jcg)
        private
        returns(uint256)
    {   
        // calc profit per gu & round mask based on this buy:  (dust goes to pot)
        uint256 _ppg = (_jcg.mul(1e18)) / (round_[_rID].gu);
        round_[_rID].maskGu = _ppg.add(round_[_rID].maskGu);

        // calculate player earning from their own buy
        // & update player earnings mask
        uint256 _plyrGu = plyrRnds_[_pID][_rID].gu;
        uint256 _pearn = (_ppg.mul(_plyrGu)) / (1e18);
        plyrRnds_[_pID][_rID].maskGu = (((round_[_rID].maskGu.mul(_plyrGu)) / (1e18)).sub(_pearn)).add(plyrRnds_[_pID][_rID].maskGu);
        
        // calculate & return dust
        return(_jcg.sub((_ppg.mul(round_[_rID].keys)) / (1e18)));
    }
    
    /**
     * @dev adds up unmasked earnings, & vault earnings, sets them all to 0
     * @return earnings in wei format
     */
    function withdrawEarnings(uint256 _pID)
        whenNotPaused
        private
        returns(uint256)
    {
        updateGenGuVault(_pID, plyr_[_pID].lrnd);

        updateReferralGu(_pID);

        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].genGu).add(plyr_[_pID].aff);

        // zero out keys if the profit doubled
        uint256 _rID = rID_; // setup local rID
        if ((_earnings + plyr_[_pID].withdraw) >= 2*(plyrRnds_[_pID][_rID].eth)) // if accumulated earnings doubled than eth-in, zero out all keys
        {
            uint256 _keys = plyrRnds_[_pID][_rID].keys;
            round_[_rID].keys = round_[_rID].keys.sub(_keys);
            plyrRnds_[_pID][_rID].keys = 0;
        }   

        // update gen vault
        updateGenVault(_pID, plyr_[_pID].lrnd);
        
        // from all vaults 
        _earnings = plyr_[_pID].gen.add(_earnings);
        if (_earnings > 0)
        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
            plyr_[_pID].genGu = 0;
            plyr_[_pID].aff = 0;
        }

        return(_earnings);
    }
    
    // /**
    //  * @dev prepares compression data and fires event for buy or reload tx&#39;s
    //  */
    // function endTx(uint256 _pID, uint256 _eth, uint256 _keys)
    //     private
    // {
    //     _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000);
    //     _eventData_.compressedIDs = _eventData_.compressedIDs + _pID + (rID_ * 10000000000000000000000000000000000000000000000000000);
        
    //     emit F3Devents.onEndTx
    //     (
    //         _eventData_.compressedData,
    //         _eventData_.compressedIDs,
    //         plyr_[_pID].name,
    //         msg.sender,
    //         _eth,
    //         _keys,
    //         _eventData_.winnerAddr,
    //         _eventData_.winnerName,
    //         _eventData_.amountWon,
    //         _eventData_.newPot,
    //         _eventData_.jcgAmount,
    //         _eventData_.genAmount,
    //         _eventData_.potAmount,
    //         airDropPot_
    //     );
    // }
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
        require(
            msg.sender == 0x18E90Fc6F70344f53EBd4f6070bf6Aa23e2D748C ||
            msg.sender == 0x8b4DA1827932D71759687f925D17F81Fc94e3A9D ||
            msg.sender == 0x8e0d985f3Ec1857BEc39B76aAabDEa6B31B67d53 ||
            msg.sender == 0x7ac74Fcc1a71b106F12c55ee8F802C9F672Ce40C ||
			msg.sender == 0xF39e044e1AB204460e06E87c6dca2c6319fC69E3,
            "only team just can activate"
        );

		// make sure that its been linked.
        // require(address(otherF3D_) != address(0), "must link to other FoMo3D first");
        
        // can only be ran once
        require(activated_ == false, "fomo3d already activated");
        
        // activate the contract 
        activated_ = true;
        
        // lets start first round
		rID_ = 1;
        round_[1].strt = now;
        round_[1].end = now + rndInit_;
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
        // bytes32 winnerName;         // winner name
        uint256 amountWon;          // amount won
        uint256 newPot;             // amount in new pot
        uint256 jcgAmount;          // amount distributed to jcg
        uint256 genAmount;          // amount distributed to gen
        uint256 potAmount;          // amount added to pot
    }
    struct Player {
        address addr;   // player address
        // bytes32 name;   // player name
        uint256 win;    // winnings vault
        uint256 gen;    // general vault
        uint256 genGu;  // general gu vault
        uint256 aff;    // affiliate vault
        uint256 lrnd;   // last round played
        uint256 laff;   // last affiliate id used
        uint256 withdraw; // sum of withdraw
        uint256 gu;     
    }
    struct PlayerRounds {
        uint256 eth;    // eth player has added to round
        uint256 keys;   // keys
        uint256 gu;     // gu
        uint256 maskKey;   // player mask key
        uint256 maskGu;   // player mask gu
        // uint256 ico;    // ICO phase investment
    }
    struct Round {
        uint256 plyr;   // pID of player in lead
        uint256 end;    // time ends/ended
        bool ended;     // has round end function been ran
        uint256 strt;   // time round started
        uint256 keys;   // keys
        uint256 gu;     // gu
        uint256 eth;    // total eth in
        uint256 pot;    // eth to pot (during round) / final amount paid to winner (after round ends)
        uint256 maskKey;   // global mask on key shares
        uint256 maskGu;   // global mask on gu shares
        // uint256 ico;    // total eth sent in during ICO phase
        // uint256 icoGen; // total eth for gen during ICO phase
        // uint256 icoAvg; // average key price for ICO phase
    }
    struct PlayerPhrases {
        uint256 eth;   // amount of eth in of the referral
        uint256 guRewarded;  // if have taken the gu through referral
        uint256 lastClaimedPhID; // at which phID player has claimed the remaining gu
    }
    struct Phrase {
        uint256 eth;   // amount of total eth in of the referral
        uint256 guGiven; // amount of gu distributed 
        uint256 mask;  // a rate of remainGu per ethIn shares
    }
    struct Fee {
        uint256 gen;    // % of buy in thats paid to key holders of current round
        uint256 jcg;    // % of buy in thats paid to jcg holders
    }
    struct PotSplit {
        uint256 gen;    // % of pot thats paid to key holders of current round
        uint256 jcg;    // % of pot thats paid to jcg holders
    }
}

//==============================================================================
//  |  _      _ _ | _  .
//  |<(/_\/  (_(_||(_  .
//=======/======================================================================
library F3DKeysCalcLong {
    using SafeMath for *;
    // /**
    //  * @dev calculates number of keys received given X eth 
    //  * @param _curEth current amount of eth in contract 
    //  * @param _newEth eth being spent
    //  * @return amount of ticket purchased
    //  */
    // function keysRec(uint256 _curEth, uint256 _newEth)
    //     internal
    //     pure
    //     returns (uint256)
    // {
    //     return(keys((_curEth).add(_newEth)).sub(keys(_curEth)));
    // }

    function keysRec(uint256 _curEth, uint256 _newEth)
        internal
        pure
        returns (uint256)
    {
        uint _startEth;
        uint _incrRate;
        uint _initPrice;

        if (_curEth < 500e18) {
            _startEth = 0;
            _initPrice = 33333; //3e-5;
            _incrRate = 50000000; //2e-8;
        }
        else if (_curEth < 1000e18) {
            _startEth = 500e18;
            _initPrice =  25000; // 4e-5;
            _incrRate = 50000000; //2e-8;
        }
        else if (_curEth < 2000e18) {
            _startEth = 1000e18;
            _initPrice = 20000; //5e-5;
            _incrRate = 50000000; //2e-8;;
        }
        else if (_curEth < 4000e18) {
            _startEth = 2000e18;
            _initPrice = 12500; //8e-5;
            _incrRate = 26666666; //3.75e-8;
        }
        else if (_curEth < 8000e18) {
            _startEth = 4000e18;
            _initPrice = 5000; //2e-4;
            _incrRate = 17777777; //5.625e-8;
        }
        else if (_curEth < 16000e18) {
            _startEth = 8000e18;
            _initPrice = 2500; // 4e-4;
            _incrRate = 10666666; //9.375e-8;
        }
        else if (_curEth < 32000e18) {
            _startEth = 16000e18;
            _initPrice = 1000; //0.001;
            _incrRate = 5688282; //1.758e-7;
        }
        else if (_curEth < 64000e18) {
            _startEth = 32000e18;
            _initPrice = 250; //0.004;
            _incrRate = 2709292; //3.691e-7;
        }
        else if (_curEth < 128000e18) {
            _startEth = 64000e18;
            _initPrice = 62; //0.016;
            _incrRate = 1161035; //8.613e-7;
        }
        else if (_curEth < 256000e18) {
            _startEth = 128000e18;
            _initPrice = 14; //0.071;
            _incrRate = 451467; //2.215e-6;
        }
        else if (_curEth < 512000e18) {
            _startEth = 256000e18;
            _initPrice = 2; //0.354;
            _incrRate = 144487; //6.921e-6;
        }
        else if (_curEth < 1024000e18) {
            _startEth = 512000e18;
            _initPrice = 0; //2.126;
            _incrRate = 40128; //2.492e-5;
        }
        else {
            _startEth = 1024000e18;
            _initPrice = 0;
            _incrRate = 40128; //2.492e-5;
        }


        uint256 finalPrice = ((_curEth - _startEth)/1e18).mul(1/_incrRate) + (1/_initPrice); 

        return _newEth.div(finalPrice);   
    }
    
    // /**
    //  * @dev calculates amount of eth received if you sold X keys 
    //  * @param _curKeys current amount of keys that exist 
    //  * @param _sellKeys amount of keys you wish to sell
    //  * @return amount of eth received
    //  */
    // function ethRec(uint256 _curKeys, uint256 _sellKeys)
    //     internal
    //     pure
    //     returns (uint256)
    // {
    //     return((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
    // }

    // /**
    //  * @dev calculates how many keys would exist with given an amount of eth
    //  * @param _eth eth "in contract"
    //  * @return number of keys that would exist
    //  */
    // function keys(uint256 _eth) 
    //     internal
    //     pure
    //     returns(uint256)
    // {
    //     return ((((((_eth).mul(1e18)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000);
    // }
    
    // /**
    //  * @dev calculates how much eth would be in contract given a number of keys
    //  * @param _keys number of keys "in contract" 
    //  * @return eth that would exists
    //  */
    // function eth(uint256 _keys) 
    //     internal
    //     pure
    //     returns(uint256)  
    // {
    //     return ((78125000).mul(_keys.sq()).add(((149999843750000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
    // }
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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
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