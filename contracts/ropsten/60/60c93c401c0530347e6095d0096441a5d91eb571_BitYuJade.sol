pragma solidity ^0.4.24;

/**
 * @title BitYuJade
 */

//=================================================
// Events
//=================================================

contract JadeEvents {
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
        uint256 jadeBought,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 pearlAmount,
        uint256 megaAmount,
        uint256 genAmount,
        uint256 potAmount
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
        uint256 pearlAmount,
        uint256 megaAmount,
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
        uint256 pearlAmount,
        uint256 megaAmount,
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
        uint256 pearlAmount,
        uint256 megaAmount,
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
    
}

//=================================================
// Contract Setup
//=================================================

contract modularLong is JadeEvents {}

contract BitYuJade is modularLong {
    using SafeMath for *;
    using NameFilter for string;
    using JadeCalc for uint256;
	
    DiviesInterface constant private Divies = DiviesInterface(0x76af1ffc00536b20357644ea28f1fe0ac5cb8912);
    BitYuIncForwarderInterface constant private Bit_Yu_Inc = BitYuIncForwarderInterface(0x38210dfc6D57521e40E16021F3605F0f2Be08DC9);
	PlayerBookInterface constant private PlayerBook = PlayerBookInterface(0x0BD5478530fbdf31bfd90e6Cf7Bf12f13D424032);
    
/**
 * @dev Game Settings
 **/
    string constant public name = "BitYu Jade";
    string constant public symbol = "JADE";
	uint256 private roundExtra_ = 10 minutes;                     // length of the very first ICO 
    uint256 private roundGap_ = 2 minutes;                        // length of ICO phase, set to 1 year for EOS.
    uint256 constant private roundInit_ = 1 hours;                // round timer starts at this
    uint256 constant private roundIncrement_ = 30 seconds;        // every full jade purchased adds this much to the timer
    uint256 constant private roundMax_ = 24 hours;                // max length a round timer can be

    address megaAddress = 0x0;
/**
 * @dev Data Setup (data used to store game info that changes)
 **/
	uint256 public roundID_;    // round id number / total rounds that have happened

/**
 * @dev Player Data
 **/
    mapping (address => uint256) public pIDxAddr_;          // (addr => pID) returns player id by address
    mapping (bytes32 => uint256) public pIDxName_;          // (name => pID) returns player id by name
    mapping (uint256 => JadeDatasets.Player) public player_;   // (pID => data) player data
    mapping (uint256 => mapping (uint256 => JadeDatasets.PlayerRounds)) public playerRounds_;    // (pID => rID => data) player round data by player id & round id
    mapping (uint256 => mapping (bytes32 => bool)) public playerNames_; // (pID => name => bool) list of names a player owns.  (used so you can change your display name amongst any name you own)

//****************
// ROUND DATA 
//****************
    mapping (uint256 => JadeDatasets.Round) public round_;   // (rID => data) round data
    mapping (uint256 => mapping(uint256 => uint256)) public rndTmEth_;      // (rID => tID => data) eth in per team, by round id and team id
//****************
// TEAM FEE DATA 
//****************
    mapping (uint256 => JadeDatasets.TeamFee) public fees_;          // (team => fees) fee distribution by team
    mapping (uint256 => JadeDatasets.PotSplit) public potSplit_;     // (team => fees) pot split distribution by team

//=================================================
// Constructor
//=================================================

    constructor()
        public
    {
		// Team allocation structures
        // 0 = Blue Dragon
        // 1 = White Tiger
        // 2 = Red Phoenix
        // 3 = Green Tortoise

		// Team allocation percentages
        // (Jade, Pearls, MEGA) + (Pot , Referrals, Community)
            // Referrals / Community rewards are mathematically designed to come from the winner&#39;s share of the pot.
        /* 
        35% to the jackpot
        42% to other jade holders as dividends
        5% to other pearls holders as dividends
        4% to MEGA token holders as dividends
        4% to the development team
        10% to your referrer
        */
        fees_[0] = JadeDatasets.TeamFee(42,5,4);     

        /*
        40% to the jackpot
        32% to other jade holders as dividends
        10% to other PEARLS HOLDERS as dividends!
        4% to MEGA token holders as dividends
        4% to the development team
        10% to your referrer
        */
        fees_[1] = JadeDatasets.TeamFee(32,10,4); 

        /*
        70% to the JACKPOT!
        12% to other jade holders as dividends
        0% to other pearls holders as dividends
        4% to MEGA token holders as dividends
        4% to the development team
        10% to your referrer
        */
        fees_[2] = JadeDatasets.TeamFee(12,0,4);  

        /* 25% to the jackpot
        47% to other jade holders as dividends
        5% to other pearls holders as dividends
        9% to MEGA HOLDERS as dividends!
        4% to the development team
        10% to your referrer
        */
        fees_[3] = JadeDatasets.TeamFee(47,5,9);   

        // how to split up the final pot based on which team was picked
        // (Jade, Pearl)
        potSplit_[0] = JadeDatasets.PotSplit(25,0,0);  
        potSplit_[1] = JadeDatasets.PotSplit(0,25,0);  
        potSplit_[2] = JadeDatasets.PotSplit(0,0,0);  
        potSplit_[3] = JadeDatasets.PotSplit(0,0,25); 
	}

//=================================================
// Modifiers
//=================================================

    /**
     * @dev used to make sure no one can interact with contract until it has 
     * been activated. 
     */
    modifier isActivated() {
        require(activated_ == true, "Contract is not yet activated"); 
        _;
    }
    
    /**
     * @dev prevents contracts from interacting with Jade 
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
        require(_eth >= 1000000000, "Transaction amount is too small");
        require(_eth <= 100000000000000000000000, "Transaction amount is too large");
        _;    
    }

    /**
    * @dev make sure only BitYu team members can use
    */
    modifier isBitYuTeam() {
        require(
            msg.sender == 0xfE6312f2350B8752923ED05fdfBeb96fbD5c781e ||
            msg.sender == 0x577a0AD1cA4011924255A7A44F3f70aB5A4B62dF,
            "only BitYu team can activate"
        );
        _;
    }
    

//=================================================
// Public Functions
//=================================================

    /**
     * @dev emergency buy uses last stored affiliate ID and team Blue Dragon
     */
    function()
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        // set up our tx event data and determine if player is new or not
        JadeDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
            
        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];
        
        // buy core 
        buyCore(_pID, player_[_pID].laff, 2, _eventData_);
    }
    
    /**
     * @dev converts all incoming ethereum to jade.
     * @param _affCode the ID/address/name of the player who gets the affiliate fee
     * @param _team what team is the player playing for?
     */
    function buyXid(uint256 _affCode, uint256 _team)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        // set up our tx event data and determine if player is new or not
        JadeDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        
        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];
        
        // manage affiliate residuals
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == 0 || _affCode == _pID)
        {
            // use last stored affiliate code 
            _affCode = player_[_pID].laff;
            
        // if affiliate code was given & its not the same as previously stored 
        } else if (_affCode != player_[_pID].laff) {
            // update last affiliate 
            player_[_pID].laff = _affCode;
        }
        
        // verify a valid team was selected
        _team = verifyTeam(_team);
        
        // buy core 
        buyCore(_pID, _affCode, _team, _eventData_);
    }
    
    function buyXaddr(address _affCode, uint256 _team)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        // set up our tx event data and determine if player is new or not
        JadeDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        
        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];
        
        // manage affiliate residuals
        uint256 _affID;
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == address(0) || _affCode == msg.sender)
        {
            // use last stored affiliate code
            _affID = player_[_pID].laff;
        
        // if affiliate code was given    
        } else {
            // get affiliate ID from aff Code 
            _affID = pIDxAddr_[_affCode];
            
            // if affID is not the same as previously stored 
            if (_affID != player_[_pID].laff)
            {
                // update last affiliate
                player_[_pID].laff = _affID;
            }
        }
        
        // verify a valid team was selected
        _team = verifyTeam(_team);
        
        // buy core 
        buyCore(_pID, _affID, _team, _eventData_);
    }
    
    function buyXname(bytes32 _affCode, uint256 _team)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        // set up our tx event data and determine if player is new or not
        JadeDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        
        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];
        
        // manage affiliate residuals
        uint256 _affID;
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == &#39;&#39; || _affCode == player_[_pID].name)
        {
            // use last stored affiliate code
            _affID = player_[_pID].laff;
        
        // if affiliate code was given
        } else {
            // get affiliate ID from aff Code
            _affID = pIDxName_[_affCode];
            
            // if affID is not the same as previously stored
            if (_affID != player_[_pID].laff)
            {
                // update last affiliate
                player_[_pID].laff = _affID;
            }
        }
        
        // verify a valid team was selected
        _team = verifyTeam(_team);
        
        // buy core 
        buyCore(_pID, _affID, _team, _eventData_);
    }
    
    /**
     * @dev essentially the same as buy, but instead of you sending ether 
     * from your wallet, it uses your unwithdrawn earnings.
     * @param _affCode the ID/address/name of the player who gets the affiliate fee
     * @param _team what team is the player playing for?
     * @param _eth amount of earnings to use (remainder returned to gen vault)
     */
    function reLoadXid(uint256 _affCode, uint256 _team, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
        // set up our tx event data
        JadeDatasets.EventReturns memory _eventData_;
        
        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];
        
        // manage affiliate residuals
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == 0 || _affCode == _pID)
        {
            // use last stored affiliate code 
            _affCode = player_[_pID].laff;
            
        // if affiliate code was given & its not the same as previously stored 
        } else if (_affCode != player_[_pID].laff) {
            // update last affiliate 
            player_[_pID].laff = _affCode;
        }

        // verify a valid team was selected
        _team = verifyTeam(_team);

        // reload core
        reLoadCore(_pID, _affCode, _team, _eth, _eventData_);
    }
    
    function reLoadXaddr(address _affCode, uint256 _team, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
        // set up our tx event data
        JadeDatasets.EventReturns memory _eventData_;
        
        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];
        
        // manage affiliate residuals
        uint256 _affID;
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == address(0) || _affCode == msg.sender)
        {
            // use last stored affiliate code
            _affID = player_[_pID].laff;
        
        // if affiliate code was given    
        } else {
            // get affiliate ID from aff Code 
            _affID = pIDxAddr_[_affCode];
            
            // if affID is not the same as previously stored 
            if (_affID != player_[_pID].laff)
            {
                // update last affiliate
                player_[_pID].laff = _affID;
            }
        }
        
        // verify a valid team was selected
        _team = verifyTeam(_team);
        
        // reload core
        reLoadCore(_pID, _affID, _team, _eth, _eventData_);
    }
    
    function reLoadXname(bytes32 _affCode, uint256 _team, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
        // set up our tx event data
        JadeDatasets.EventReturns memory _eventData_;
        
        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];
        
        // manage affiliate residuals
        uint256 _affID;
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == &#39;&#39; || _affCode == player_[_pID].name)
        {
            // use last stored affiliate code
            _affID = player_[_pID].laff;
        
        // if affiliate code was given
        } else {
            // get affiliate ID from aff Code
            _affID = pIDxName_[_affCode];
            
            // if affID is not the same as previously stored
            if (_affID != player_[_pID].laff)
            {
                // update last affiliate
                player_[_pID].laff = _affID;
            }
        }
        
        // verify a valid team was selected
        _team = verifyTeam(_team);
        
        // reload core
        reLoadCore(_pID, _affID, _team, _eth, _eventData_);
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
        uint256 _rID = roundID_;
        
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
            JadeDatasets.EventReturns memory _eventData_;
            
            // end the round (distributes pot)
			round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);
            
			// get their earnings
            _eth = withdrawEarnings(_pID);
            
            // gib moni
            if (_eth > 0)
                player_[_pID].addr.transfer(_eth);    
            
            // build event data
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;
            
            // fire withdraw and distribute event
            emit JadeEvents.onWithdrawAndDistribute
            (
                msg.sender, 
                player_[_pID].name, 
                _eth, 
                _eventData_.compressedData, 
                _eventData_.compressedIDs, 
                _eventData_.winnerAddr, 
                _eventData_.winnerName, 
                _eventData_.amountWon, 
                _eventData_.newPot, 
                _eventData_.pearlAmount, 
                _eventData_.megaAmount,
                _eventData_.genAmount
            );
            
        // in any other situation
        } else {
            // get their earnings
            _eth = withdrawEarnings(_pID);
            
            // gib moni
            if (_eth > 0)
                player_[_pID].addr.transfer(_eth);
            
            // fire withdraw event
            emit JadeEvents.onWithdraw(_pID, msg.sender, player_[_pID].name, _eth, _now);
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
        emit JadeEvents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, player_[_affID].addr, player_[_affID].name, _paid, now);
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
        emit JadeEvents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, player_[_affID].addr, player_[_affID].name, _paid, now);
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
        emit JadeEvents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, player_[_affID].addr, player_[_affID].name, _paid, now);
    }

    function setMegaAddress(address _megaAddress) 
        isBitYuTeam()
        public
    {
        megaAddress = _megaAddress;
    }

//=================================================
// Getters
//=================================================

    /**
     * @dev return the price buyer will pay for next 1 individual jade.
     * @return price for next jade bought (in wei format)
     */
    function getBuyPrice()
        public 
        view 
        returns(uint256)
    {  
        // setup local rID
        uint256 _rID = roundID_;
        
        // grab time
        uint256 _now = now;
        
        // are we in a round?
        if (_now > round_[_rID].strt + roundGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].jade.add(1000000000000000000)).ethRec(1000000000000000000) );
        else // rounds over.  need price for new round
            return ( 75000000000000 ); // init
    }
    
    /**
     * @dev returns time left.  dont spam this, you&#39;ll ddos yourself from your node 
     * provider
     * @return time left in seconds
     */
    function getTimeLeft()
        public
        view
        returns(uint256)
    {
        // setup local rID
        uint256 _rID = roundID_;
        
        // grab time
        uint256 _now = now;
        
        if (_now < round_[_rID].end)
            if (_now > round_[_rID].strt + roundGap_)
                return( (round_[_rID].end).sub(_now) );
            else
                return( (round_[_rID].strt + roundGap_).sub(_now) );
        else
            return(0);
    }
    
    /**
     * @dev returns player earnings per vaults 
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
        uint256 _rID = roundID_;
        
        // if round has ended.  but round end has not been run (so contract has not distributed winnings)
        if (now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
            // if player is winner 
            if (round_[_rID].plyr == _pID)
            {
                return
                (
                    (player_[_pID].win).add( ((round_[_rID].pot).mul(48)) / 100 ),
                    (player_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(playerRounds_[_pID][_rID].mask)   ),
                    player_[_pID].aff
                );
            // if player is not the winner
            } else {
                return
                (
                    player_[_pID].win,
                    (player_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(playerRounds_[_pID][_rID].mask)  ),
                    player_[_pID].aff
                );
            }
            
        // if round is still going on, or round has ended and round end has been ran
        } else {
            return
            (
                player_[_pID].win,
                (player_[_pID].gen).add(calcUnMaskedEarnings(_pID, player_[_pID].lrnd)),
                player_[_pID].aff
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
        return(  ((((round_[_rID].mask).add(((((round_[_rID].pot).mul(potSplit_[round_[_rID].team].gen)) / 100).mul(1000000000000000000)) / (round_[_rID].jade))).mul(playerRounds_[_pID][_rID].jade)) / 1000000000000000000)  );
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
     * @return dragons eth in for round
     * @return tigers eth in for round
     * @return phoenixs eth in for round
     * @return tortoises eth in for round
     */
    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, bytes32, uint256, uint256, uint256, uint256)
    {
        // setup local rID
        uint256 _rID = roundID_;
        
        return
        (
            round_[_rID].ico,               //0
            _rID,                           //1
            round_[_rID].jade,              //2
            round_[_rID].end,               //3
            round_[_rID].strt,              //4
            round_[_rID].pot,               //5
            (round_[_rID].team + (round_[_rID].plyr * 10)),     //6
            player_[round_[_rID].plyr].addr,  //7
            player_[round_[_rID].plyr].name,  //8
            rndTmEth_[_rID][0],             //9
            rndTmEth_[_rID][1],             //10
            rndTmEth_[_rID][2],             //11
            rndTmEth_[_rID][3]              //12
        );
    }

    /**
     * @dev returns player info based on address.  if no address is given, it will 
     * use msg.sender 
     * @param _addr address of the player you want to lookup 
     * @return player ID 
     * @return player name
     * @return jade owned (current round)
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
        uint256 _rID = roundID_;
        
        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];
        
        return
        (
            _pID,                                 //0
            player_[_pID].name,                   //1
            playerRounds_[_pID][_rID].jade,       //2
            player_[_pID].win,                    //3
            (player_[_pID].gen).add(calcUnMaskedEarnings(_pID, player_[_pID].lrnd)),       //4
            player_[_pID].aff,                    //5
            playerRounds_[_pID][_rID].eth         //6
        );
    }

    /**
    * @dev returns the remaining balance of mega tokens available to JADE 
    **/
    function getMegaBalance()
        public 
        view 
        returns(uint256)
    {
        return ERC20(megaAddress).balanceOf(address(this));
    }

//=================================================
// Core Logic (this + tools + calcs + modules = our softwares engine)
//=================================================

    /**
     * @dev logic runs whenever a buy order is executed.  determines how to handle 
     * incoming eth depending on if we are in an active round or not
     */
    function buyCore(uint256 _pID, uint256 _affID, uint256 _team, JadeDatasets.EventReturns memory _eventData_)
        private
    {
        // setup local rID
        uint256 _rID = roundID_;
        
        // grab time
        uint256 _now = now;
        
        // if round is active
        if (_now > round_[_rID].strt + roundGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) 
        {
            // call core 
            core(_rID, _pID, msg.value, _affID, _team, _eventData_);
        
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
                emit JadeEvents.onBuyAndDistribute
                (
                    msg.sender, 
                    player_[_pID].name, 
                    msg.value, 
                    _eventData_.compressedData, 
                    _eventData_.compressedIDs, 
                    _eventData_.winnerAddr, 
                    _eventData_.winnerName, 
                    _eventData_.amountWon, 
                    _eventData_.newPot, 
                    _eventData_.pearlAmount, 
                    _eventData_.megaAmount,
                    _eventData_.genAmount
                );
            }
            
            // put eth in players vault 
            player_[_pID].gen = player_[_pID].gen.add(msg.value);


        }
    }
    
    /**
     * @dev logic runs whenever a reload order is executed.  determines how to handle 
     * incoming eth depending on if we are in an active round or not 
     */
    function reLoadCore(uint256 _pID, uint256 _affID, uint256 _team, uint256 _eth, JadeDatasets.EventReturns memory _eventData_)
        private
    {
        // setup local rID
        uint256 _rID = roundID_;
        
        // grab time
        uint256 _now = now;
        
        // if round is active
        if (_now > round_[_rID].strt + roundGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) 
        {
            // get earnings from all vaults and return unused to gen vault
            // because we use a custom safemath library.  this will throw if player 
            // tried to spend more eth than they have.
            player_[_pID].gen = withdrawEarnings(_pID).sub(_eth);
            
            // call core 
            core(_rID, _pID, _eth, _affID, _team, _eventData_);
        
        // if round is not active and end round needs to be ran   
        } else if (_now > round_[_rID].end && round_[_rID].ended == false) {
            // end the round (distributes pot) & start new round
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);
                
            // build event data
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;
                
            // fire buy and distribute event 
            emit JadeEvents.onReLoadAndDistribute
            (
                msg.sender, 
                player_[_pID].name, 
                _eventData_.compressedData, 
                _eventData_.compressedIDs, 
                _eventData_.winnerAddr, 
                _eventData_.winnerName, 
                _eventData_.amountWon, 
                _eventData_.newPot, 
                _eventData_.pearlAmount, 
                _eventData_.megaAmount,
                _eventData_.genAmount
            );
        }
    }
    
    /**
     * @dev this is the core logic for any buy/reload that happens while a round 
     * is live.
     */
    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, JadeDatasets.EventReturns memory _eventData_)
        private
    {
        // if player is new to round
        if (playerRounds_[_pID][_rID].jade == 0)
            _eventData_ = managePlayer(_pID, _eventData_);
        
        // early round eth limiter 
        if (round_[_rID].eth < 100000000000000000000 && playerRounds_[_pID][_rID].eth.add(_eth) > 1000000000000000000)
        {
            uint256 _availableLimit = (1000000000000000000).sub(playerRounds_[_pID][_rID].eth);
            uint256 _refund = _eth.sub(_availableLimit);
            player_[_pID].gen = player_[_pID].gen.add(_refund);
            _eth = _availableLimit;
        }
        
        // if eth left is greater than min eth allowed (sorry no pocket lint)
        if (_eth > 1000000000) 
        {
            
            // mint the new jade
            uint256 _jade = (round_[_rID].eth).jadeRec(_eth);
            
            // if they bought at least 1 whole jade
            if (_jade >= 1000000000000000000)
            {
            updateTimer(_jade, _rID);

            // set new leaders
            if (round_[_rID].plyr != _pID)
                round_[_rID].plyr = _pID;  
            if (round_[_rID].team != _team)
                round_[_rID].team = _team; 
            
            // set the new leader bool to true
            _eventData_.compressedData = _eventData_.compressedData + 100;
        }
            
            // update player 
            playerRounds_[_pID][_rID].jade = _jade.add(playerRounds_[_pID][_rID].jade);
            playerRounds_[_pID][_rID].eth = _eth.add(playerRounds_[_pID][_rID].eth);
            
            // update round
            round_[_rID].jade = _jade.add(round_[_rID].jade);
            round_[_rID].eth = _eth.add(round_[_rID].eth);
            rndTmEth_[_rID][_team] = _eth.add(rndTmEth_[_rID][_team]);
    
            // distribute eth
            _eventData_ = distributeExternal(_rID, _pID, _eth, _affID, _team, _eventData_);
            _eventData_ = distributeInternal(_rID, _pID, _eth, _team, _jade, _eventData_);
            
            //Send MEGA tokens (80 MEGA for every eth spent)
            if(megaAddress != 0x0)
            {
                uint256 tokenAmount = _eth.mul(80);
                ERC20(megaAddress).transferFrom(player_[_pID].addr, address(this), tokenAmount);
            }

            // call end tx function to fire end tx event.
		    endTx(_pID, _team, _eth, _jade, _eventData_);
        }


    }

//=================================================
// Calculators
//=================================================

    /**
     * @dev calculates unmasked earnings (just calculates, does not update mask)
     * @return earnings in wei format
     */
    function calcUnMaskedEarnings(uint256 _pID, uint256 _rIDlast)
        private
        view
        returns(uint256)
    {
        return(  (((round_[_rIDlast].mask).mul(playerRounds_[_pID][_rIDlast].jade)) / (1000000000000000000)).sub(playerRounds_[_pID][_rIDlast].mask)  );
    }
    
    /** 
     * @dev returns the amount of jade you would get given an amount of eth. 
     * @param _rID round ID you want price for
     * @param _eth amount of eth sent in 
     * @return jade received 
     */
    function calcJadeReceived(uint256 _rID, uint256 _eth)
        public
        view
        returns(uint256)
    {
        // grab time
        uint256 _now = now;
        
        // are we in a round?
        if (_now > round_[_rID].strt + roundGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].eth).jadeRec(_eth) );
        else // rounds over.  need jade for new round
            return ( (_eth).jade() );
    }
    
    /** 
     * @dev returns current eth price for X jade.  
     * @param _jade number of jade desired (in 18 decimal format)
     * @return amount of eth needed to send
     */
    function iWantXJade(uint256 _jade)
        public
        view
        returns(uint256)
    {
        // setup local rID
        uint256 _rID = roundID_;
        
        // grab time
        uint256 _now = now;
        
        // are we in a round?
        if (_now > round_[_rID].strt + roundGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].jade.add(_jade)).ethRec(_jade) );
        else // rounds over.  need price for new round
            return ( (_jade).eth() );
    }

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
        if (player_[_pID].addr != _addr)
            player_[_pID].addr = _addr;
        if (player_[_pID].name != _name)
            player_[_pID].name = _name;
        if (player_[_pID].laff != _laff)
            player_[_pID].laff = _laff;
        if (playerNames_[_pID][_name] == false)
            playerNames_[_pID][_name] = true;
    }
    
    /**
     * @dev receives entire player name list 
     */
    function receivePlayerNameList(uint256 _pID, bytes32 _name)
        external
    {
        require (msg.sender == address(PlayerBook), "your not playerNames contract... hmmm..");
        if(playerNames_[_pID][_name] == false)
            playerNames_[_pID][_name] = true;
    }   
        
    /**
     * @dev gets existing or registers new pID.  use this when a player may be new
     * @return pID 
     */
    function determinePID(JadeDatasets.EventReturns memory _eventData_)
        private
        returns (JadeDatasets.EventReturns)
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        // if player is new to this version of Jade
        if (_pID == 0)
        {
            // grab their player ID, name and last aff ID, from player names contract 
            _pID = PlayerBook.getPlayerID(msg.sender);
            bytes32 _name = PlayerBook.getPlayerName(_pID);
            uint256 _laff = PlayerBook.getPlayerLAff(_pID);
            
            // set up player account 
            pIDxAddr_[msg.sender] = _pID;
            player_[_pID].addr = msg.sender;
            
            if (_name != "")
            {
                pIDxName_[_name] = _pID;
                player_[_pID].name = _name;
                playerNames_[_pID][_name] = true;
            }
            
            if (_laff != 0 && _laff != _pID)
                player_[_pID].laff = _laff;
            
            // set the new player bool to true
            _eventData_.compressedData = _eventData_.compressedData + 1;
        } 
        return (_eventData_);
    }
    
    /**
     * @dev checks to make sure user picked a valid team.  if not sets team 
     * to default (Blue Dragon)
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
    function managePlayer(uint256 _pID, JadeDatasets.EventReturns memory _eventData_)
        private
        returns (JadeDatasets.EventReturns)
    {
        // if player has played a previous round, move their unmasked earnings
        // from that round to gen vault.
        if (player_[_pID].lrnd != 0)
            updateGenVault(_pID, player_[_pID].lrnd);
            
        // update player&#39;s last round played
        player_[_pID].lrnd = roundID_;
            
        // set the joined round bool to true
        _eventData_.compressedData = _eventData_.compressedData + 10;
        
        return(_eventData_);
    }
    
    /**
     * @dev ends the round. manages paying out winner/splitting up pot
     */
    function endRound(JadeDatasets.EventReturns memory _eventData_)
        private
        returns (JadeDatasets.EventReturns)
    {
        // setup local rID
        uint256 _rID = roundID_;
        
        // grab our winning player and team id&#39;s
        uint256 _winPID = round_[_rID].plyr;
        uint256 _winTID = round_[_rID].team;
        
        // grab our pot amount
        uint256 _pot = round_[_rID].pot;
        
        // calculate our winner share, community rewards, gen share, 
        // pearl share, and amount reserved for next pot 
        uint256 _win = (_pot.mul(48)) / 100;
        uint256 _com = (_pot / 25); //%4 to community
        uint256 _gen = (_pot.mul(potSplit_[_winTID].gen)) / 100;
        uint256 _pearl = (_pot.mul(potSplit_[_winTID].pearl)) / 100;
        uint256 _res = (((_pot.sub(_win)).sub(_com)).sub(_gen)).sub(_pearl);
        
        // calculate ppt for round mask
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].jade);
        uint256 _dust = _gen.sub((_ppt.mul(round_[_rID].jade)) / 1000000000000000000);
        if (_dust > 0)
        {
            _gen = _gen.sub(_dust);
            _res = _res.add(_dust);
        }
        
        // pay our winner
        player_[_winPID].win = _win.add(player_[_winPID].win);
        
        // community rewards
        if (!address(Bit_Yu_Inc).call.value(_com)(bytes4(keccak256("deposit()"))))
        {
            // This ensures BitYu cannot influence the outcome of Jade with
            // bank migrations by breaking outgoing transactions.
            // Something we would never do. But that&#39;s not the point.
            _pearl = _pearl.add(_com);
            _com = 0;
        }
        
        // distribute gen portion to jade holders
        round_[_rID].mask = _ppt.add(round_[_rID].mask);
        
        // send share for pearl to divies
        if (_pearl > 0)
            Divies.deposit.value(_pearl)();
            
        // prepare event data
        _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * 100000000000000000000000000) + (_winTID * 100000000000000000);
        _eventData_.winnerAddr = player_[_winPID].addr;
        _eventData_.winnerName = player_[_winPID].name;
        _eventData_.amountWon = _win;
        _eventData_.genAmount = _gen;
        _eventData_.pearlAmount = _pearl;
        _eventData_.megaAmount = (_pot.mul(potSplit_[_winTID].mega)) / 100;
        _eventData_.newPot = _res;
        
        // start next round
        roundID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(roundInit_).add(roundGap_);
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
            player_[_pID].gen = _earnings.add(player_[_pID].gen);
            // zero out their earnings by updating mask
            playerRounds_[_pID][_rIDlast].mask = _earnings.add(playerRounds_[_pID][_rIDlast].mask);
        }
    }
    
    /**
     * @dev updates round timer based on number of whole jade bought.
     */
    function updateTimer(uint256 _jade, uint256 _rID)
        private
    {
        // grab time
        uint256 _now = now;
        
        // calculate time based on number of jade bought
        uint256 _newTime;
        if (_now > round_[_rID].end && round_[_rID].plyr == 0)
            _newTime = (((_jade) / (1000000000000000000)).mul(roundIncrement_)).add(_now);
        else
            _newTime = (((_jade) / (1000000000000000000)).mul(roundIncrement_)).add(round_[_rID].end);
        
        // compare to max and set new end time
        if (_newTime < (roundMax_).add(_now))
            round_[_rID].end = _newTime;
        else
            round_[_rID].end = roundMax_.add(_now);
    }
    
    /**
     * @dev distributes eth based on fees to com, aff, and pearl
     */
    function distributeExternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, JadeDatasets.EventReturns memory _eventData_)
        private
        returns(JadeDatasets.EventReturns)
    {
        // pay 4% out to community rewards
        uint256 _com = _eth / 25;
        uint256 _pearl;
        uint256 _mega;
        if (!address(Bit_Yu_Inc).call.value(_com)(bytes4(keccak256("deposit()"))))
        {
            // This ensures BitYu cannot influence the outcome of Jade with
            // bank migrations by breaking outgoing transactions.
            // Something we would never do. But that&#39;s not the point.
            _pearl = _com;
            _com = 0;
        }
        
        // distribute share to affiliate
        uint256 _aff = _eth / 10;
        
        // decide what to do with affiliate share of fees
        // affiliate must not be self, and must have a name registered
        if (_affID != _pID && player_[_affID].name != &#39;&#39;) {
            player_[_affID].aff = _aff.add(player_[_affID].aff);
            emit JadeEvents.onAffiliatePayout(_affID, player_[_affID].addr, player_[_affID].name, _rID, _pID, _aff, now);
        } else {
            _pearl = _aff;
        }
        
        // pay out pearl
        _pearl = _pearl.add((_eth.mul(fees_[_team].pearl)) / (100));
        if (_pearl > 0)
        {
            // deposit to divies contract
            Divies.deposit.value(_pearl)();
            
            // set up event data
            _eventData_.pearlAmount = _pearl.add(_eventData_.pearlAmount);
        }

        // pay out mega
        _mega = _mega.add((_eth.mul(fees_[_team].mega)) / (100));
        if (_mega > 0)
        {
            // deposit to divies contract
            Divies.deposit.value(_mega)();
            
            // set up event data
            _eventData_.megaAmount = _mega.add(_eventData_.megaAmount);
        }
        
        return(_eventData_);
    }
    
    /**
     * @dev distributes eth based on fees to gen and pot
     */
    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _team, uint256 _jade, JadeDatasets.EventReturns memory _eventData_)
        private
        returns(JadeDatasets.EventReturns)
    {
        // calculate gen share
        uint256 _gen = (_eth.mul(fees_[_team].gen)) / 100;
         
        // update eth balance (eth = eth - (com share + pot swap share + aff share + pearl share ))
        _eth = _eth.sub(((_eth.mul(14)) / 100).add((_eth.mul(fees_[_team].pearl)) / 100));
        
        // calculate pot 
        uint256 _pot = _eth.sub(_gen);
        
        // distribute gen share (thats what updateMasks() does) and adjust
        // balances for dust.
        uint256 _dust = updateMasks(_rID, _pID, _gen, _jade);
        if (_dust > 0)
            _gen = _gen.sub(_dust);
        
        // add eth to pot
        round_[_rID].pot = _pot.add(_dust).add(round_[_rID].pot);
        
        // set up event data
        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _pot;
        
        return(_eventData_);
    }

    /**
     * @dev updates masks for round and player when jade are bought
     * @return dust left over 
     */
    function updateMasks(uint256 _rID, uint256 _pID, uint256 _gen, uint256 _jade)
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
        
        // calc profit per jade & round mask based on this buy:  (dust goes to pot)
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].jade);
        round_[_rID].mask = _ppt.add(round_[_rID].mask);
            
        // calculate player earning from their own buy (only based on the jade
        // they just bought).  & update player earnings mask
        uint256 _pearn = (_ppt.mul(_jade)) / (1000000000000000000);
        playerRounds_[_pID][_rID].mask = (((round_[_rID].mask.mul(_jade)) / (1000000000000000000)).sub(_pearn)).add(playerRounds_[_pID][_rID].mask);
        
        // calculate & return dust
        return(_gen.sub((_ppt.mul(round_[_rID].jade)) / (1000000000000000000)));
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
        updateGenVault(_pID, player_[_pID].lrnd);
        
        // from vaults 
        uint256 _earnings = (player_[_pID].win).add(player_[_pID].gen).add(player_[_pID].aff);
        if (_earnings > 0)
        {
            player_[_pID].win = 0;
            player_[_pID].gen = 0;
            player_[_pID].aff = 0;
        }

        return(_earnings);
    }
    
    /**
     * @dev prepares compression data and fires event for buy or reload tx&#39;s
     */
    function endTx(uint256 _pID, uint256 _team, uint256 _eth, uint256 _jade, JadeDatasets.EventReturns memory _eventData_)
        private
    {
        _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000) + (_team * 100000000000000000000000000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + _pID + (roundID_ * 10000000000000000000000000000000000000000000000000000);
        
        emit JadeEvents.onEndTx
        (
            _eventData_.compressedData,
            _eventData_.compressedIDs,
            player_[_pID].name,
            msg.sender,
            _eth,
            _jade,
            _eventData_.winnerAddr,
            _eventData_.winnerName,
            _eventData_.amountWon,
            _eventData_.newPot,
            _eventData_.pearlAmount,
            _eventData_.megaAmount,
            _eventData_.genAmount,
            _eventData_.potAmount
        );
    }

//=================================================
// Security
//=================================================

    /** upon contract deploy, it will be deactivated.  this is a one time
     * use function that will activate the contract.  we do this so devs 
     * have time to set things up on the web end                            **/
    bool public activated_ = false;
    function activate()
        isBitYuTeam()
        public
    {        
        // can only be ran once
        require(activated_ == false, "Jade already activated");
        
        // activate the contract 
        activated_ = true;
        
        // lets start first round
		roundID_ = 1;
        round_[1].strt = now + roundExtra_ - roundGap_;
        round_[1].end = now + roundInit_ + roundExtra_;
    }
    
}

//=================================================
// Structs
//=================================================

library JadeDatasets {
    //compressedData key
    // [76-33][32][31][30][29][28-18][17][16-6][5-3][2][1][0]
        // 0 - new player (bool)
        // 1 - joined round (bool)
        // 2 - new  leader (bool)
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
        address winnerAddr;         // winner address
        bytes32 winnerName;         // winner name
        uint256 amountWon;          // amount won
        uint256 newPot;             // amount in new pot
        uint256 pearlAmount;        // amount distributed to pearl
        uint256 megaAmount;
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
        uint256 jade;   // jade
        uint256 mask;   // player mask 
        uint256 ico;    // ICO phase investment
    }
    struct Round {
        uint256 plyr;   // pID of player in lead
        uint256 team;   // tID of team in lead
        uint256 end;    // time ends/ended
        bool ended;     // has round end function been ran
        uint256 strt;   // time round started
        uint256 jade;   // jade
        uint256 eth;    // total eth in
        uint256 pot;    // eth to pot (during round) / final amount paid to winner (after round ends)
        uint256 mask;   // global mask
        uint256 ico;    // total eth sent in during ICO phase
        uint256 icoGen; // total eth for gen during ICO phase
        uint256 icoAvg; // average jade price for ICO phase
    }
    struct TeamFee {
        uint256 gen;    // % of buy in thats paid to jade holders of current round
        uint256 pearl;  // % of buy in thats paid to pearl holders
        uint256 mega;   // % of buy in thats paid to mega holders
    }
    struct PotSplit {
        uint256 gen;    // % of pot thats paid to jade holders of current round
        uint256 pearl;  // % of pot thats paid to pearl holders
        uint256 mega;   // % of buy in thats paid to mega holders
    }
}

//=================================================
// Jade Calc
//=================================================

library JadeCalc {
    using SafeMath for *;
    /**
     * @dev calculates number of jade received given X eth 
     * @param _curEth current amount of eth in contract 
     * @param _newEth eth being spent
     * @return amount of ticket purchased
     */
    function jadeRec(uint256 _curEth, uint256 _newEth)
        internal
        pure
        returns (uint256)
    {
        return(jade((_curEth).add(_newEth)).sub(jade(_curEth)));
    }
    
    /**
     * @dev calculates amount of eth received if you sold X jade 
     * @param _curJade current amount of jade that exist 
     * @param _sellJade amount of jade you wish to sell
     * @return amount of eth received
     */
    function ethRec(uint256 _curJade, uint256 _sellJade)
        internal
        pure
        returns (uint256)
    {
        return((eth(_curJade)).sub(eth(_curJade.sub(_sellJade))));
    }

    /**
     * @dev calculates how many jade would exist with given an amount of eth
     * @param _eth eth "in contract"
     * @return number of jade that would exist
     */
    function jade(uint256 _eth) 
        internal
        pure
        returns(uint256)
    {
        return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000);
    }
    
    /**
     * @dev calculates how much eth would be in contract given a number of jade
     * @param _jade number of jade "in contract" 
     * @return eth that would exists
     */
    function eth(uint256 _jade) 
        internal
        pure
        returns(uint256)  
    {
        return ((78125000).mul(_jade.sq()).add(((149999843750000).mul(_jade.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
    }
}

//=================================================
// Interfaces
//=================================================

interface DiviesInterface {
    function deposit() external payable;
}

interface BitYuIncForwarderInterface {
    function deposit() external payable returns(bool);
    function status() external view returns(address, address, bool);
    function startMigration(address _newCorpBank) external returns(bool);
    function cancelMigration() external returns(bool);
    function finishMigration() external returns(bool);
    function setup(address _firstCorpBank) external;
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

interface ERC20 {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function balanceOf(address _who) external view returns (uint256);
}
/**
 * @title NameFilter
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