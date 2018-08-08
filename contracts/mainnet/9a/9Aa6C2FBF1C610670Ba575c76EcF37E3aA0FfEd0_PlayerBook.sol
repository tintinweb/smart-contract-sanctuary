pragma solidity ^0.4.24;

interface PlayerBookReceiverInterface {
    function receivePlayerInfo(uint256 _pID, address _addr, bytes32 _name, uint256 _laff) external;
    function receivePlayerNameList(uint256 _pID, bytes32 _name) external;
}


contract PlayerBook {
    using NameFilter for string;
    using SafeMath for uint256;

    address private admin = msg.sender;
    //==============================================================================
    //     _| _ _|_ _    _ _ _|_    _   .
    //    (_|(_| | (_|  _\(/_ | |_||_)  .
    //=============================|================================================
    uint256 public registrationFee_ = 10 finney;            // price to register a name
    mapping(uint256 => PlayerBookReceiverInterface) public games_;  // mapping of our game interfaces for sending your account info to games
    mapping(address => bytes32) public gameNames_;          // lookup a games name
    mapping(address => uint256) public gameIDs_;            // lokup a games ID
    uint256 public gID_;        // total number of games
    uint256 public pID_;        // total number of players
    mapping (address => uint256) public pIDxAddr_;          // (addr => pID) returns player id by address
    mapping (bytes32 => uint256) public pIDxName_;          // (name => pID) returns player id by name
    mapping (uint256 => Player) public plyr_;               // (pID => data) player data
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_; // (pID => name => bool) list of names a player owns.  (used so you can change your display name amoungst any name you own)
    mapping (uint256 => mapping (uint256 => bytes32)) public plyrNameList_; // (pID => nameNum => name) list of names a player owns
    struct Player {
        address addr;
        bytes32 name;
        uint256 laff;
        uint256 names;
    }
    //==============================================================================
    //     _ _  _  __|_ _    __|_ _  _  .
    //    (_(_)| |_\ | | |_|(_ | (_)|   .  (initial data setup upon contract deploy)
    //==============================================================================
    constructor()
    public
    {
        // premine the dev names (sorry not sorry)
        // No keys are purchased with this method, it&#39;s simply locking our addresses,
        // PID&#39;s and names for referral codes.
        plyr_[1].addr = 0x8e0d985f3Ec1857BEc39B76aAabDEa6B31B67d53;
        plyr_[1].name = "justo";
        plyr_[1].names = 1;
        pIDxAddr_[0x8e0d985f3Ec1857BEc39B76aAabDEa6B31B67d53] = 1;
        pIDxName_["justo"] = 1;
        plyrNames_[1]["justo"] = true;
        plyrNameList_[1][1] = "justo";

        plyr_[2].addr = 0x8b4DA1827932D71759687f925D17F81Fc94e3A9D;
        plyr_[2].name = "mantso";
        plyr_[2].names = 1;
        pIDxAddr_[0x8b4DA1827932D71759687f925D17F81Fc94e3A9D] = 2;
        pIDxName_["mantso"] = 2;
        plyrNames_[2]["mantso"] = true;
        plyrNameList_[2][1] = "mantso";

        plyr_[3].addr = 0x7ac74Fcc1a71b106F12c55ee8F802C9F672Ce40C;
        plyr_[3].name = "sumpunk";
        plyr_[3].names = 1;
        pIDxAddr_[0x7ac74Fcc1a71b106F12c55ee8F802C9F672Ce40C] = 3;
        pIDxName_["sumpunk"] = 3;
        plyrNames_[3]["sumpunk"] = true;
        plyrNameList_[3][1] = "sumpunk";

        plyr_[4].addr = 0x18E90Fc6F70344f53EBd4f6070bf6Aa23e2D748C;
        plyr_[4].name = "inventor";
        plyr_[4].names = 1;
        pIDxAddr_[0x18E90Fc6F70344f53EBd4f6070bf6Aa23e2D748C] = 4;
        pIDxName_["inventor"] = 4;
        plyrNames_[4]["inventor"] = true;
        plyrNameList_[4][1] = "inventor";

        pID_ = 4;
    }
    //==============================================================================
    //     _ _  _  _|. |`. _  _ _  .
    //    | | |(_)(_||~|~|(/_| _\  .  (these are safety checks)
    //==============================================================================
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


    modifier isRegisteredGame()
    {
        require(gameIDs_[msg.sender] != 0);
        _;
    }
    //==============================================================================
    //     _    _  _ _|_ _  .
    //    (/_\/(/_| | | _\  .
    //==============================================================================
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
    //==============================================================================
    //     _  _ _|__|_ _  _ _  .
    //    (_|(/_ |  | (/_| _\  . (for UI & viewing things on etherscan)
    //=====_|=======================================================================
    function checkIfNameValid(string _nameStr)
    public
    view
    returns(bool)
    {
        bytes32 _name = _nameStr.nameFilter();
        if (pIDxName_[_name] == 0)
            return (true);
        else
            return (false);
    }
    //==============================================================================
    //     _    |_ |. _   |`    _  __|_. _  _  _  .
    //    |_)|_||_)||(_  ~|~|_|| |(_ | |(_)| |_\  .  (use these to interact with contract)
    //====|=========================================================================
    /**
     * @dev registers a name.  UI will always display the last name you registered.
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
     * @param _affCode affiliate ID, address, or name of who refered you
     * @param _all set to true if you want this to push your info to all games
     * (this might cost a lot of gas)
     */
    function registerNameXID(string _nameString, uint256 _affCode, bool _all)
    isHuman()
    public
    payable
    {
        // make sure name fees paid
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        // filter name + condition checks
        bytes32 _name = NameFilter.nameFilter(_nameString);

        // set up address
        address _addr = msg.sender;

        // set up our tx event data and determine if player is new or not
        bool _isNewPlayer = determinePID(_addr);

        // fetch player id
        uint256 _pID = pIDxAddr_[_addr];

        // manage affiliate residuals
        // if no affiliate code was given, no new affiliate code was given, or the
        // player tried to use their own pID as an affiliate code, lolz
        if (_affCode != 0 && _affCode != plyr_[_pID].laff && _affCode != _pID)
        {
            // update last affiliate
            plyr_[_pID].laff = _affCode;
        } else if (_affCode == _pID) {
            _affCode = 0;
        }

        // register name
        registerNameCore(_pID, _addr, _affCode, _name, _isNewPlayer, _all);
    }

    function registerNameXaddr(string _nameString, address _affCode, bool _all)
    isHuman()
    public
    payable
    {
        // make sure name fees paid
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        // filter name + condition checks
        bytes32 _name = NameFilter.nameFilter(_nameString);

        // set up address
        address _addr = msg.sender;

        // set up our tx event data and determine if player is new or not
        bool _isNewPlayer = determinePID(_addr);

        // fetch player id
        uint256 _pID = pIDxAddr_[_addr];

        // manage affiliate residuals
        // if no affiliate code was given or player tried to use their own, lolz
        uint256 _affID;
        if (_affCode != address(0) && _affCode != _addr)
        {
            // get affiliate ID from aff Code
            _affID = pIDxAddr_[_affCode];

            // if affID is not the same as previously stored
            if (_affID != plyr_[_pID].laff)
            {
                // update last affiliate
                plyr_[_pID].laff = _affID;
            }
        }

        // register name
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);
    }

    function registerNameXname(string _nameString, bytes32 _affCode, bool _all)
    isHuman()
    public
    payable
    {
        // make sure name fees paid
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        // filter name + condition checks
        bytes32 _name = NameFilter.nameFilter(_nameString);

        // set up address
        address _addr = msg.sender;

        // set up our tx event data and determine if player is new or not
        bool _isNewPlayer = determinePID(_addr);

        // fetch player id
        uint256 _pID = pIDxAddr_[_addr];

        // manage affiliate residuals
        // if no affiliate code was given or player tried to use their own, lolz
        uint256 _affID;
        if (_affCode != "" && _affCode != _name)
        {
            // get affiliate ID from aff Code
            _affID = pIDxName_[_affCode];

            // if affID is not the same as previously stored
            if (_affID != plyr_[_pID].laff)
            {
                // update last affiliate
                plyr_[_pID].laff = _affID;
            }
        }

        // register name
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);
    }

    /**
     * @dev players, if you registered a profile, before a game was released, or
     * set the all bool to false when you registered, use this function to push
     * your profile to a single game.  also, if you&#39;ve  updated your name, you
     * can use this to push your name to games of your choosing.
     * -functionhash- 0x81c5b206
     * @param _gameID game id
     */
    function addMeToGame(uint256 _gameID)
    isHuman()
    public
    {
        require(_gameID <= gID_, "silly player, that game doesn&#39;t exist yet");
        address _addr = msg.sender;
        uint256 _pID = pIDxAddr_[_addr];
        require(_pID != 0, "hey there buddy, you dont even have an account");
        uint256 _totalNames = plyr_[_pID].names;

        // add players profile and most recent name
        games_[_gameID].receivePlayerInfo(_pID, _addr, plyr_[_pID].name, plyr_[_pID].laff);

        // add list of all names
        if (_totalNames > 1)
            for (uint256 ii = 1; ii <= _totalNames; ii++)
                games_[_gameID].receivePlayerNameList(_pID, plyrNameList_[_pID][ii]);
    }

    /**
     * @dev players, use this to push your player profile to all registered games.
     * -functionhash- 0x0c6940ea
     */
    function addMeToAllGames()
    isHuman()
    public
    {
        address _addr = msg.sender;
        uint256 _pID = pIDxAddr_[_addr];
        require(_pID != 0, "hey there buddy, you dont even have an account");
        uint256 _laff = plyr_[_pID].laff;
        uint256 _totalNames = plyr_[_pID].names;
        bytes32 _name = plyr_[_pID].name;

        for (uint256 i = 1; i <= gID_; i++)
        {
            games_[i].receivePlayerInfo(_pID, _addr, _name, _laff);
            if (_totalNames > 1)
                for (uint256 ii = 1; ii <= _totalNames; ii++)
                    games_[i].receivePlayerNameList(_pID, plyrNameList_[_pID][ii]);
        }

    }

    /**
     * @dev players use this to change back to one of your old names.  tip, you&#39;ll
     * still need to push that info to existing games.
     * -functionhash- 0xb9291296
     * @param _nameString the name you want to use
     */
    function useMyOldName(string _nameString)
    isHuman()
    public
    {
        // filter name, and get pID
        bytes32 _name = _nameString.nameFilter();
        uint256 _pID = pIDxAddr_[msg.sender];

        // make sure they own the name
        require(plyrNames_[_pID][_name] == true, "umm... thats not a name you own");

        // update their current name
        plyr_[_pID].name = _name;
    }

    //==============================================================================
    //     _ _  _ _   | _  _ . _  .
    //    (_(_)| (/_  |(_)(_||(_  .
    //=====================_|=======================================================
    function registerNameCore(uint256 _pID, address _addr, uint256 _affID, bytes32 _name, bool _isNewPlayer, bool _all)
    private
    {
        // if names already has been used, require that current msg sender owns the name
        if (pIDxName_[_name] != 0)
            require(plyrNames_[_pID][_name] == true, "sorry that names already taken");

        // add name to player profile, registry, and name book
        plyr_[_pID].name = _name;
        pIDxName_[_name] = _pID;
        if (plyrNames_[_pID][_name] == false)
        {
            plyrNames_[_pID][_name] = true;
            plyr_[_pID].names++;
            plyrNameList_[_pID][plyr_[_pID].names] = _name;
        }

        // registration fee goes directly to community rewards
        admin.transfer(address(this).balance);

        // push player info to games
        if (_all == true)
            for (uint256 i = 1; i <= gID_; i++)
                games_[i].receivePlayerInfo(_pID, _addr, _name, _affID);

        // fire event
        emit onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, msg.value, now);
    }
    //==============================================================================
    //    _|_ _  _ | _  .
    //     | (_)(_)|_\  .
    //==============================================================================
    function determinePID(address _addr)
    private
    returns (bool)
    {
        if (pIDxAddr_[_addr] == 0)
        {
            pID_++;
            pIDxAddr_[_addr] = pID_;
            plyr_[pID_].addr = _addr;

            // set the new player bool to true
            return (true);
        } else {
            return (false);
        }
    }
    //==============================================================================
    //   _   _|_ _  _ _  _ |   _ _ || _  .
    //  (/_>< | (/_| | |(_||  (_(_|||_\  .
    //==============================================================================
    function getPlayerID(address _addr)
    isRegisteredGame()
    external
    returns (uint256)
    {
        determinePID(_addr);
        return (pIDxAddr_[_addr]);
    }
    function getPlayerName(uint256 _pID)
    external
    view
    returns (bytes32)
    {
        return (plyr_[_pID].name);
    }
    function getPlayerLAff(uint256 _pID)
    external
    view
    returns (uint256)
    {
        return (plyr_[_pID].laff);
    }
    function getPlayerAddr(uint256 _pID)
    external
    view
    returns (address)
    {
        return (plyr_[_pID].addr);
    }
    function getNameFee()
    external
    view
    returns (uint256)
    {
        return(registrationFee_);
    }
    function registerNameXIDFromDapp(address _addr, bytes32 _name, uint256 _affCode, bool _all)
    isRegisteredGame()
    external
    payable
    returns(bool, uint256)
    {
        // make sure name fees paid
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        // set up our tx event data and determine if player is new or not
        bool _isNewPlayer = determinePID(_addr);

        // fetch player id
        uint256 _pID = pIDxAddr_[_addr];

        // manage affiliate residuals
        // if no affiliate code was given, no new affiliate code was given, or the
        // player tried to use their own pID as an affiliate code, lolz
        uint256 _affID = _affCode;
        if (_affID != 0 && _affID != plyr_[_pID].laff && _affID != _pID)
        {
            // update last affiliate
            plyr_[_pID].laff = _affID;
        } else if (_affID == _pID) {
            _affID = 0;
        }

        // register name
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);

        return(_isNewPlayer, _affID);
    }
    function registerNameXaddrFromDapp(address _addr, bytes32 _name, address _affCode, bool _all)
    isRegisteredGame()
    external
    payable
    returns(bool, uint256)
    {
        // make sure name fees paid
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        // set up our tx event data and determine if player is new or not
        bool _isNewPlayer = determinePID(_addr);

        // fetch player id
        uint256 _pID = pIDxAddr_[_addr];

        // manage affiliate residuals
        // if no affiliate code was given or player tried to use their own, lolz
        uint256 _affID;
        if (_affCode != address(0) && _affCode != _addr)
        {
            // get affiliate ID from aff Code
            _affID = pIDxAddr_[_affCode];

            // if affID is not the same as previously stored
            if (_affID != plyr_[_pID].laff)
            {
                // update last affiliate
                plyr_[_pID].laff = _affID;
            }
        }

        // register name
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);

        return(_isNewPlayer, _affID);
    }
    function registerNameXnameFromDapp(address _addr, bytes32 _name, bytes32 _affCode, bool _all)
    isRegisteredGame()
    external
    payable
    returns(bool, uint256)
    {
        // make sure name fees paid
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        // set up our tx event data and determine if player is new or not
        bool _isNewPlayer = determinePID(_addr);

        // fetch player id
        uint256 _pID = pIDxAddr_[_addr];

        // manage affiliate residuals
        // if no affiliate code was given or player tried to use their own, lolz
        uint256 _affID;
        if (_affCode != "" && _affCode != _name)
        {
            // get affiliate ID from aff Code
            _affID = pIDxName_[_affCode];

            // if affID is not the same as previously stored
            if (_affID != plyr_[_pID].laff)
            {
                // update last affiliate
                plyr_[_pID].laff = _affID;
            }
        }

        // register name
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);

        return(_isNewPlayer, _affID);
    }

    //==============================================================================
    //   _ _ _|_    _   .
    //  _\(/_ | |_||_)  .
    //=============|================================================================
    function addGame(address _gameAddress, string _gameNameStr)
    public
    {
        require(gameIDs_[_gameAddress] == 0, "derp, that games already been registered");
        gID_++;
        bytes32 _name = _gameNameStr.nameFilter();
        gameIDs_[_gameAddress] = gID_;
        gameNames_[_gameAddress] = _name;
        games_[gID_] = PlayerBookReceiverInterface(_gameAddress);

        games_[gID_].receivePlayerInfo(1, plyr_[1].addr, plyr_[1].name, 0);
        games_[gID_].receivePlayerInfo(2, plyr_[2].addr, plyr_[2].name, 0);
        games_[gID_].receivePlayerInfo(3, plyr_[3].addr, plyr_[3].name, 0);
        games_[gID_].receivePlayerInfo(4, plyr_[4].addr, plyr_[4].name, 0);
    }

    function setRegistrationFee(uint256 _fee)
    public
    {
        registrationFee_ = _fee;
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