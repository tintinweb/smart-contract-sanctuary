pragma solidity 0.4.25;


interface FSForwarderInterface {
    function deposit() external payable returns(bool);
}


/// @title Contract for managing player names and affiliate payments.
/// @notice This contract manages player names and affiliate payments
/// from registered games. Players can buy multiple names and select
/// which name to be used. Players who buy affiliate memberships can
/// receive affiliate payments from registered games.
/// Players can withdraw affiliate payments at any time.
/// @dev The address of the forwarder is hardcoded. Check &#39;TODO&#39; before
/// deploy.
contract FSBook {
    using NameFilter for string;
    using SafeMath for uint256;

    // TODO : CHECK THE ADDRESS!!!
    FSForwarderInterface constant private FSKingCorp = FSForwarderInterface(0x3a2321DDC991c50518969B93d2C6B76bf5309790);

    // data    
    uint256 public registrationFee_ = 10 finney;            // price to register a name
    uint256 public affiliateFee_ = 500 finney;              // price to become an affiliate
    uint256 public pID_;        // total number of players

    // (addr => pID) returns player id by address
    mapping (address => uint256) public pIDxAddr_;
    // (name => pID) returns player id by name
    mapping (bytes32 => uint256) public pIDxName_;
    // (pID => data) player data
    mapping (uint256 => Player) public plyr_;
    // (pID => name => bool) list of names a player owns.  (used so you can change your display name amoungst any name you own)
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_;
    // (pID => nameNum => name) list of names a player owns
    mapping (uint256 => mapping (uint256 => bytes32)) public plyrNameList_;
    // registered games
    mapping (address => bool) public registeredGames_;


    struct Player {
        address addr;
        bytes32 name;
        bool hasAff;

        uint256 aff;
        uint256 withdrawnAff;

        uint256 laff;
        uint256 affT2;
        uint256 names;
    }


    // constructor
    constructor()
        public
    {
        // premine the dev names (sorry not sorry)
        // No keys are purchased with this method, it&#39;s simply locking our addresses,
        // PID&#39;s and names for referral codes.
        plyr_[1].addr = 0xe0b005384df8f4d80e9a69b6210ec1929a935d97;
        plyr_[1].name = "sportking";
        plyr_[1].hasAff = true;
        plyr_[1].names = 1;
        pIDxAddr_[0xe0b005384df8f4d80e9a69b6210ec1929a935d97] = 1;
        pIDxName_["sportking"] = 1;
        plyrNames_[1]["sportking"] = true;
        plyrNameList_[1][1] = "sportking";

        pID_ = 1;
    }

    // modifiers
    
    /// @dev prevents contracts from interacting with fsbook
    modifier isHuman() {
        address _addr = msg.sender;
        require (_addr == tx.origin, "Human only");

        uint256 _codeLength;
        assembly { _codeLength := extcodesize(_addr) }
        require(_codeLength == 0, "Human only");
        _;
    }
    

    // TODO: Check address!!!
    /// @dev Check if caller is one of the owner(s).
    modifier onlyDevs() 
    {
        // TODO : CHECK THE ADDRESS!!!
        require(msg.sender == 0xe0b005384df8f4d80e9a69b6210ec1929a935d97 ||
            msg.sender == 0xe3ff68fb79fee1989fb67eb04e196e361ecaec3e ||
            msg.sender == 0xb914843d2e56722a2c133eff956d1f99b820d468 ||
            msg.sender == 0xc52FA2C9411fCd4f58be2d6725094689C46242f2, "msg sender is not a dev");
        _;
    }


    /// @dev Check if caller is registered.
    modifier isRegisteredGame() {
        require(registeredGames_[msg.sender] == true, "sender is not registered");
        _;
    }
    
    // events

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
        uint256 timestamp
    );

    event onNewAffiliate
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        uint256 amountPaid,
        uint256 timestamp
    );

    event onUseOldName
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        uint256 timestamp
    );

    event onGameRegistered
    (
        address indexed gameAddress,
        bool enabled,
        uint256 timestamp
    );

    event onWithdraw
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        uint256 amount,
        uint256 timestamp  
    );

    // getters:
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

    // public functions:
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
     * (this might cost a lot of gas)
     */

    function registerNameXID(string _nameString, uint256 _affCode)
        external
        payable 
        isHuman()
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
        uint256 _affID = _affCode;
        if (_affCode != 0 && _affCode != plyr_[_pID].laff && _affCode != _pID) 
        {
            // update last affiliate 
            plyr_[_pID].laff = _affCode;
        } else if (_affCode == _pID) {
            _affID = 0;
        }
        
        // register name 
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer);
    }
    

    function registerNameXaddr(string _nameString, address _affCode)
        external
        payable 
        isHuman()
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
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer);
    }
    

    function registerNameXname(string _nameString, bytes32 _affCode)
        external
        payable 
        isHuman()
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
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer);
    }


    function registerAffiliate()
        external
        payable
        isHuman()
    {
        // make sure name fees paid
        require (msg.value >= affiliateFee_, "umm.....  you have to pay the name fee");

        // set up address 
        address _addr = msg.sender;
        uint256 _pID = pIDxAddr_[_addr];

        require (_pID > 0, "you need to be registered");
        require (plyr_[_pID].hasAff == false, "already registered as affiliate");

        FSKingCorp.deposit.value(msg.value)();
        plyr_[_pID].hasAff = true;

        bytes32 _name = plyr_[_pID].name;

        // fire event
        emit onNewAffiliate(_pID, _addr, _name, msg.value, now);
    }


    function registerGame(address _contract, bool _enable)
        external
        isHuman()
        onlyDevs()
    {
        registeredGames_[_contract] = _enable;

        emit onGameRegistered(_contract, _enable, now);
    }
    
    /**
     * @dev players use this to change back to one of your old names.  tip, you&#39;ll
     * still need to push that info to existing games.
     * -functionhash- 0xb9291296
     * @param _nameString the name you want to use 
     */
    function useMyOldName(string _nameString)
        external
        isHuman()
    {
        // filter name, and get pID
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _pID = pIDxAddr_[_addr];
        
        // make sure they own the name 
        require(plyrNames_[_pID][_name] == true, "umm... thats not a name you own");
        
        // update their current name 
        plyr_[_pID].name = _name;

        emit onUseOldName(_pID, _addr, _name, now);
    }

    // deposit affiliate to a code
    function depositAffiliate(uint256 _pID)
        external
        payable
        isRegisteredGame()
    {
        require(plyr_[_pID].hasAff == true, "Not registered as affiliate");

        uint256 value = msg.value;
        plyr_[_pID].aff = value.add(plyr_[_pID].aff);
    }

    // withdraw money
    function withdraw()
        external
        isHuman()
    {
        address _addr = msg.sender;
        uint256 _pID = pIDxAddr_[_addr];
        bytes32 _name = plyr_[_pID].name;
        require(_pID != 0, "need to be registered");

        uint256 _remainValue = (plyr_[_pID].aff).sub(plyr_[_pID].withdrawnAff);
        if (_remainValue > 0) {
            plyr_[_pID].withdrawnAff = plyr_[_pID].aff;
            address(msg.sender).transfer(_remainValue);
        }

        emit onWithdraw(_pID, _addr, _name, _remainValue, now);
    }
    
    // core logics:
    function registerNameCore(uint256 _pID, address _addr, uint256 _affID, bytes32 _name, bool _isNewPlayer)
        private
    {
        // if names already has been used, require that current msg sender owns the name
        if (pIDxName_[_name] != 0)
            require(plyrNames_[_pID][_name] == true, "sorry that names already taken");
        
        // add name to player profile, registry, and name book
        plyr_[_pID].name = _name;
        plyr_[_pID].affT2 = _affID;
        pIDxName_[_name] = _pID;
        if (plyrNames_[_pID][_name] == false)
        {
            plyrNames_[_pID][_name] = true;
            plyr_[_pID].names++;
            plyrNameList_[_pID][plyr_[_pID].names] = _name;
        }
        
        // TODO: MODIFY THIS
        // registration fee goes directly to community rewards
        //FSKingCorp.deposit.value(address(this).balance)();
        FSKingCorp.deposit.value(msg.value)();
        
        // fire event
        emit onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, msg.value, now);
    }

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

    // external calls:
    function getPlayerID(address _addr)
        external
        isRegisteredGame()
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

    function setPlayerLAff(uint256 _pID, uint256 _lAff)
        external
        isRegisteredGame()
    {
        if (_pID != _lAff && plyr_[_pID].laff != _lAff) {
            plyr_[_pID].laff = _lAff;
        }
    }

    function getPlayerAffT2(uint256 _pID)
        external
        view
        returns (uint256)
    {
        return (plyr_[_pID].affT2);
    }

    function getPlayerAddr(uint256 _pID)
        external
        view
        returns (address)
    {
        return (plyr_[_pID].addr);
    }

    function getPlayerHasAff(uint256 _pID)
        external
        view
        returns (bool)
    {
        return (plyr_[_pID].hasAff);
    }

    function getNameFee()
        external
        view
        returns (uint256)
    {
        return(registrationFee_);
    }

    function getAffiliateFee()
        external
        view
        returns (uint256)
    {
        return (affiliateFee_);
    }
    
    function setRegistrationFee(uint256 _fee)
        external
        onlyDevs()
    {
        registrationFee_ = _fee;
    }

    function setAffiliateFee(uint256 _fee)
        external
        onlyDevs()
    {
        affiliateFee_ = _fee;
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