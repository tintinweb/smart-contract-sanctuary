pragma solidity ^0.4.24;

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

interface FoMo3DLongInterface {
    function buyXid(uint256 _affCode, uint256 _eth, bytes32 _keyType) public returns(uint256);
    function buyXaddr(address _affCode, uint256 _eth, bytes32 _keyType) public returns(uint256);
    function buyXname(bytes32 _affCode, uint256 _eth, bytes32 _keyType) public returns(uint256);

    function registerNameXid(string memory _nameString, uint256 _affCode, bool _all) public;
    function registerNameXaddr(string memory _nameString, address _affCode, bool _all) public;
    function registerNameXname(string memory _nameString, bytes32 _affCode, bool _all) public;
    
    function getBuyPrice() public returns(uint256);
    function getTimeLeft() public returns(uint256);

    function getCurrentRoundInfo() public returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
    function getPlayerInfoByAddress(address _addr) public view returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
    function getPlayerRoundInfoByID(uint256 _pID, uint256 _rID) public view returns(uint256, uint256, bool, uint256, uint256, uint256, uint256, bool, uint256, uint256, uint256, uint256, uint256, uint256);
    function getCurrentRoundTeamCos() public view returns(uint256,uint256,uint256,uint256);
    
    function sellKeys(uint256 _pID_, uint256 _keys_, bytes32 _keyType) public returns(uint256);
    function playGame(uint256 _pID, uint256 _keys, uint256 _team, bytes32 _keyType) public returns(bool,bool);
    function buyProp(uint256 _pID, uint256 _eth, uint256 _propID) public returns(uint256,uint256);
    function buyLeader(uint256 _pID, uint256 _eth) public returns(uint256,uint256);
    function iWantXKeys(uint256 _keys) public returns(uint256);
    
    function withdrawHoldVault(uint256 _pID) public returns(bool);
    function withdrawAffVault(uint256 _pID) public returns(bool);
    function withdrawWonCosFromGame(uint256 _pID, uint256 _affID, uint256 _rID) public returns(bool);
    function transferToAnotherAddr(address _to, uint256 _keys, bytes32 _keyType) public returns(bool);
    function activate() public;
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

    function div(uint256 a, uint256 b) 
    internal 
    pure 
    returns (uint256 c) 
    {
        require(b > 0);
        c = a / b;
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
    function nameFilter(string memory _input)
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
                //_temp[i] = byte(uint(_temp[i]) + 32);

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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

// "./PlayerBookInterface.sol";
// "./SafeMath.sol";
// "./NameFilter.sol";
// &#39;openzeppelin-solidity/contracts/ownership/Ownable.sol&#39;;

//==============================================================================
//     _    _  _ _|_ _  .
//    (/_\/(/_| | | _\  .
//==============================================================================
contract F3Devents {
    /*
    event debug (
        uint16 code,
        uint256 value,
        bytes32 msg
    );
    */

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
        uint256 amountWon
    );

    // (fomo3d long only) fired whenever a player tries a buy after round timer
    // hit zero, and causes end round to be ran.
    // emit F3Devents.onBuyAndDistribute
    //             (
    //                 msg.sender,
    //                 plyr_[_pID].name,
    //                 plyr_[_pID].cosd,
    //                 plyr_[_pID].cosc,
    //                 plyr_[pIDCom_].cosd,
    //                 plyr_[pIDCom_].cosc,
    //                 plyr_[_affID].affVltCosd,
    //                 plyr_[_affID].affVltCosc,
    //                 keyNum_
    //             );
    event onBuyAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 pCosd,
        uint256 pCosc,
        uint256 comCosd,
        uint256 comCosc,
        uint256 affVltCosd,
        uint256 affVltCosc,
        uint256 keyNums
    );

    // emit F3Devents.onRecHldVltCosd
    //                     (
    //                         msg.sender,
    //                         plyr_[j].name,
    //                         plyr_[j].hldVltCosd
    //                     );
    event onRecHldVltCosd
    (
        address playerAddress,
        bytes32 playerName, 
        uint256 hldVltCosd
    );

    // emit F3Devents.onSellAndDistribute
    //             (
    //                 msg.sender,
    //                 plyr_[_pID].name,
    //                 plyr_[_pID].cosd,
    //                 plyr_[_pID].cosc,
    //                 keyNum_
    //             );
    event onSellAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 pCosd,
        uint256 pCosc,
        uint256 keyNums
    );

    event onGameCore
    (
        address playerAddress,
        bytes32 playerName,
        uint256 pCosd,
        uint256 pCosc,
        uint256 plyrRnds_cosd,
        uint256 plyrRnds_cosc,
        bool plyrRnds_first,
        uint256 plyrRnds_redtPRFirst,
        uint256 plyrRnds_firstCosd,
        uint256 plyrRnds_firstCosc,
        uint256 round_cosd,
        uint256 round_cosc,
        uint256 plyrRnds_team
    );

    event onEndRoundProssRate
    (
        address playerAddress,
        bytes32 playerName,
        uint256 plyrRnds_cosd,
        uint256 plyrRnds_cosc,
        uint256 plyr_rounds,
        uint256 plyr_redt1,
        uint256 plyr_redt3
    );

    event onWin
    (
        address playerAddress,
        bytes32 playerName,
        uint256 plyrRnds_wonCosd,
        uint256 plyrRnds_wonCosc,
        uint256 plyr_lrnd
    );

    event onLoss
    (
        address playerAddress,
        bytes32 playerName,
        uint256 plyrRnds_wonCosd,
        uint256 plyrRnds_wonCosc,
        uint256 plyr_lrnd
    );
    // emit F3Devents.onEndRound
    //             (
    //                 rID_,
    //                 round_[_rID].strt,
    //                 round_[_rID].end,
    //                 round_[_rID].ended
    //             );
    // (fomo3d long only) fired whenever a player tries a reload after round timer
    // hit zero, and causes end round to be ran.
    event onEndRound
    (
        uint256 rID,
        uint256 round_strt,
        uint256 round_end,
        bool    round_ended
    );

    event onBuyProp
    (
        address playerAddress,
        bytes32 playerName,
        uint256 plyrRnds_predtPRProp,
        uint256 plyrRnds_pincrPRProp,
        uint256 plyr_predtProp,
        bool    plyrRnds_phadProp,
        uint256 plyrRnds_ppropID,
        uint256 plyrRnds_oredtPRProp,
        uint256 plyrRnds_oincrPRProp,
        uint256 plyr_oredtProp,
        bool    plyrRnds_ohadProp,
        uint256 plyrRnds_opropID,
        uint256 rndProp_oID
    );

    event onBuyLeader
    (
        address playerAddress,
        // bytes32 playerName,
        uint256 rndLd_price,
        uint256 round_plyr,
        uint256 round_team,
        uint256 rndTmEth_winRate1,
        uint256 rndTmEth_winRate2
    );
   
    event onWithdrawHoldVault
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 plyr_cosd,
        uint256 plyr_hldVltCosd
    );
    
    event onWithdrawAffVault
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 plyr_cosd,
        uint256 plyr_cosc,
        uint256 plyr_affVltCosd,
        uint256 plyr_affVltCosc
    );
    
    event onWithdrawWonCosFromGame
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 plyr_cosd,
        uint256 plyr_cosc,
        uint256 plyr_affVltCosd
    );
}

contract modularLong is F3Devents {}

contract FoMo3DLong is modularLong, Ownable, FoMo3DLongInterface {
    using SafeMath for *;
    using NameFilter for *;
    using F3DKeysCalcLong for *;

    //    otherFoMo3D private otherF3D_;
    PlayerBookInterface constant private PlayerBook = PlayerBookInterface(0x07E90e7381A949C96B654C5E833d528f3547a93d);

     //==============================================================================
    //     _ _  _  |`. _     _ _ |_ | _  _  .
    //    (_(_)| |~|~|(_||_|| (_||_)|(/__\  .  (game settings)
    //=================_|===========================================================
    string constant public name = "FoMo3D World";
    string constant public symbol = "F3DW";
    //    uint256 private rndExtra_ = extSettings.getLongExtra();     // length of the very first ICO
    uint256 constant public rndGap_ = 0; // 120 seconds;         // length of ICO phase.
    uint256 constant public rndInit_ = 4 hours;                // round timer starts at this
    // uint256 constant private rndInc_ = 30 seconds;              // every full key purchased adds this much to the timer
    // uint256 constant private rndMax_ = 24 hours;                // max length a round timer can be

    uint256 constant public rndFirst_ = 1 hours;                // a round fist step timer can be

    uint256 constant public threshould_ = 3;//超过XXX个cos

    uint256 public rID_;    // round id number / total rounds that have happened
    uint256 public plyNum_ = 2;
    uint256 public keyNum_ = 0;

    uint256 constant public pIDCom_ = 1;
    //****************
    // PLAYER DATA
    //****************
    mapping (address => uint256) public pIDxAddr_;          // (addr => pID) returns player id by address
    mapping (bytes32 => uint256) public pIDxName_;          // (name => pID) returns player id by name
    mapping (uint256 => F3Ddatasets.Player) public plyr_;   // (pID => data) player data
    mapping (uint256 => mapping (uint256 => F3Ddatasets.PlayerRounds)) public plyrRnds_;    // (pID => rID => data) player round data by player id & round id
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_; // (pID => name => bool) list of names a player owns.  (used so you can change your display name amongst any name you own)
    //****************
    // ROUND DATA
    //****************
    mapping (uint256 => F3Ddatasets.Round) public round_;   // (rID => data) round data
    mapping (uint256 => mapping(uint256 => F3Ddatasets.Team)) public rndTmEth_;      // (rID => tID => data) eth in per team, by round id and team id
    mapping (uint256 => mapping(uint256 => F3Ddatasets.Prop)) public rndProp_;      // (rID => propID => data) eth in per team, by round id and team id
    mapping (uint256 => F3Ddatasets.Leader) public rndLd_;      // (rID => data) eth in per team, by round id and team id
    
    //****************
    // TEAM FEE DATA
    //****************

    // mapping (uint256 => F3Ddatasets.Team) public teams_;          // (teamID => team)
    // mapping (uint256 => F3Ddatasets.Prop) public props_;          // (teamID => team)
    mapping (uint256 => F3Ddatasets.Fee) public fees_;          // (teamID => team)
    
    //F3Ddatasets.EventReturns  _eventData_;

    constructor()
    public
    {
        //teams
        // teams_[0] = F3Ddatasets.Team(0,70,0);
        // teams_[1] = F3Ddatasets.Team(1,30,0);
        //props
        // props_[0] = F3Ddatasets.Prop(0,5,20,20);
        // props_[1] = F3Ddatasets.Prop(1,2,0,20);
        // props_[2] = F3Ddatasets.Prop(2,2,10,0);
        // props_[3] = F3Ddatasets.Prop(3,1,0,10);
        // props_[4] = F3Ddatasets.Prop(4,1,10,0);
        //fees
        fees_[0] = F3Ddatasets.Fee(5,2,3);    //cosdBuyFee
        fees_[1] = F3Ddatasets.Fee(0,0,20);  //cosdSellFee
        fees_[2] = F3Ddatasets.Fee(4,1,0);    //coscBuyFee
        fees_[3] = F3Ddatasets.Fee(0,0,0);   //coscSellFee
    }

    // **
    //  * @dev used to make sure no one can interact with contract until it has
    //  * been activated.
    //  *
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
        //require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;
    }

    function buyXid(uint256 _affCode, uint256 _eth, bytes32 _keyType)
    isActivated()
    isHuman()
    // isWithinLimits(msg.value)
    public
    // payable
    returns(uint256)
    {
        // set up our tx event data and determine if player is new or not
        // F3Ddatasets.EventReturns memory _eventData_;
        // _eventData_ = determinePID(_eventData_);
        determinePID();

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

        // verify a valid team was selected
        // _team = verifyTeam(_team);

        // buy core
        //function buyCore(uint256 _pID, uint256 _affID, uint256 _eth, uint256 _team, bytes32 _keyType, F3Ddatasets.EventReturns memory _eventData_)
        return buyCore(_pID, _affCode,_eth, _keyType);
    }

    function buyXaddr(address _affCode, uint256 _eth, bytes32 _keyType)
    isActivated()
    isHuman()
    // isWithinLimits(msg.value)
    public
    // payable
    returns(uint256)
    {
        // set up our tx event data and determine if player is new or not
        // F3Ddatasets.EventReturns memory _eventData_;
        // _eventData_ = determinePID(_eventData_);
        determinePID();

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

        // verify a valid team was selected
        // _team = verifyTeam(_team);

        // buy core
        return buyCore(_pID, _affID, _eth, _keyType);
    }

    // function buyXname(bytes32 _affCode,  uint256 _eth, bytes32 _keyType)
    // isActivated()
    // isHuman()
    // // isWithinLimits(msg.value)
    // public
    // // payable
    // returns(uint256)
    // {
    //     // set up our tx event data and determine if player is new or not
    //     // F3Ddatasets.EventReturns memory _eventData_;
    //     // _eventData_ = determinePID(_eventData_);
    //     determinePID();
    //     // fetch player id
    //     uint256 _pID = pIDxAddr_[msg.sender];

    //     // manage affiliate residuals
    //     uint256 _affID;
    //     // if no affiliate code was given or player tried to use their own, lolz
    //     if (_affCode == &#39;&#39; || _affCode == plyr_[_pID].name)
    //     {
    //         // use last stored affiliate code
    //         _affID = plyr_[_pID].laff;

    //         // if affiliate code was given
    //     } else {
    //         // get affiliate ID from aff Code
    //         _affID = pIDxName_[_affCode];

    //         // if affID is not the same as previously stored
    //         if (_affID != plyr_[_pID].laff)
    //         {
    //             // update last affiliate
    //             plyr_[_pID].laff = _affID;
    //         }
    //     }

    //     // verify a valid team was selected
    //     // _team = verifyTeam(_team);

    //     // buy core
    //     return buyCore(_pID, _affID,_eth, _keyType);
    // }


    function registerNameXid(string memory _nameString, uint256 _affCode, bool _all)
    isHuman()
    public
    // payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXIDFromDapp.value(_paid)(_addr, _name, _affCode, _all);

        uint256 _pID = pIDxAddr_[_addr];

        // fire event
        emit F3Devents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }

    function registerNameXaddr(string   memory  _nameString, address _affCode, bool _all)
    isHuman()
    public
    // payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXaddrFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);

        uint256 _pID = pIDxAddr_[_addr];

        // fire event
        emit F3Devents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }

    // function registerNameXname(string memory  _nameString, bytes32 _affCode, bool _all)
    // isHuman()
    // public
    // // payable
    // {
    //     bytes32 _name = _nameString.nameFilter();
    //     address _addr = msg.sender;
    //     uint256 _paid = msg.value;
    //     (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXnameFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);

    //     uint256 _pID = pIDxAddr_[_addr];

    //     // fire event
    //     emit F3Devents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    // }
    /**
     * @dev return the price buyer will pay for next 1 individual key.
     * -functionhash- 0x018a25e8
     * @return price for next key bought (in wei format)
     */
    function getBuyPrice()
    public
    // view
    returns(uint256)
    {
        // // setup local rID
        // uint256 _rID = rID_;

        // // grab time
        // uint256 _now = now;
        uint256 _price = 10**16;
        uint256 _keyNum = keyNum_;
        // are we in a round?
        // if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) {
        //     //return  uint256((10 ** 16).mul( ((1+3/10000) ** (round_[_rID].cosd.add(round_[_rID].cosc)-1))));
        //     uint256 _count = round_[_rID].cosd.add(round_[_rID].cosc);
            while(_keyNum > 0){
                _price = _price + _price*3/10000;
                _keyNum--;
            }
            return _price;
        // }
        // else // rounds over.  need price for new round
        //     return ( 10**16 ); // init
    }

    function getTimeLeft()
    public
    // view
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

  
    
    //  struct Round {
    //     uint256 plyr;   // pID of player in lead
    //     uint256 team;   // tID of team in lead
    //     uint256 end;    // time ends/ended
    //     bool ended;     // has round end function been ran
    //     uint256 strt;   // time round started
    //     uint256 cosd;   // keys
    //     uint256 cosc;   // keys
    //     uint256 eth;    // total eth in
    //     uint256 ico;    // total eth sent in during ICO phase
    //     uint256 winTeam;
    // }     
    // 
    function getCurrentRoundInfo()
    public
    // view
    returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        // setup local rID
        uint256 _rID = rID_;

        return
        (
            _rID,                           
            round_[_rID].plyr,
            round_[_rID].team,
            round_[_rID].cosd,              
            round_[_rID].cosc,              
            round_[_rID].strt,              
            round_[_rID].end,                                                
            round_[_rID].winTeam           
        );
    }


    //  struct Player {
    //     address addr;   // player address
    //     bytes32 name;   // player name
    //     uint256 cosd;    // winnings vault
    //     uint256 cosc;    // winnings vault
    //     uint256 aff;    // affiliate vault
    //     uint256 lrnd;   // last round played
    //     uint256 laff;   // last affiliate id used
    //     uint256 rounds; //超过xxxcosd的轮数累计
    //     uint256 redtProp; //买道具赠送的累计亏损减少率
    //     uint256 redt1;
    //     uint256 redt3;
    //     uint256 affVltCosd;
    //     uint256 affVltCosc;
    //     uint256 hldVltCosd;
    // }
    //  
    function getPlayerInfoByAddress(address _addr)
    public
    view
    returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        // setup local rID
        // uint256 _rID = rID_;
        // address _addr = _addr_;

        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];

        return
        (
            _pID,                              
            plyr_[_pID].name,                  
            plyr_[_pID].cosd,       
            plyr_[_pID].cosc,
            plyr_[_pID].lrnd,                  
            plyr_[_pID].laff,
            plyr_[_pID].rounds,
            plyr_[_pID].redtProp,
            plyr_[_pID].redt1,
            plyr_[_pID].redt3,
            plyr_[_pID].affVltCosd,
            plyr_[_pID].affVltCosc,
            plyr_[_pID].hldVltCosd
        );
    }

    // struct PlayerRounds {
    //     uint256 eth;    // eth player has added to round (used for eth limiter)
    //     uint256 cosd;   // keys
    //     uint256 cosc;   // keys
    //     bool hadProp;
    //     uint256 propID;
    //     uint256 redtPRProp; //lossReductionRate，玩家当前回合道具总亏损减少率
    //     uint256 incrPRProp; //Income increase rate收入增加率
    //     uint256 team;
    //     bool first;
    //     uint256 firstCosd;//第一阶段投入的COS资金，可减少20% 亏损率
    //     uint256 firstCosc;//第一阶段投入的COS资金，可减少20% 亏损率
    //     uint256 redtInFirst;
    //     uint256 wonCosd;
    //     uint256 wonCosc;
    //     uint256 wonEth;
    // }
   
    function getPlayerRoundInfoByID(uint256 _pID, uint256 _rID)
    public
    view
    returns(uint256, uint256, bool, uint256, uint256, uint256, uint256, bool, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        // setup local rID
        uint256 _rID_ = _rID;
        uint256 _pID_ = _pID;

        return
        (              
            plyrRnds_[_pID_][_rID_].cosd,       
            plyrRnds_[_pID_][_rID_].cosc,
            plyrRnds_[_pID_][_rID_].hadProp,                  
            plyrRnds_[_pID_][_rID_].propID,
            plyrRnds_[_pID_][_rID_].redtPRProp,
            plyrRnds_[_pID_][_rID_].incrPRProp,
            plyrRnds_[_pID_][_rID_].team,
            plyrRnds_[_pID_][_rID_].first,
            plyrRnds_[_pID_][_rID_].firstCosd,
            plyrRnds_[_pID_][_rID_].firstCosc,
            plyrRnds_[_pID_][_rID_].wonCosd,
            plyrRnds_[_pID_][_rID_].wonCosc,
            plyrRnds_[_pID_][_rID_].wonCosdRcd,
            plyrRnds_[_pID_][_rID_].wonCoscRcd        
        );
    }

    function getCurrentRoundTeamCos()
    public
    view
    returns(uint256, uint256, uint256, uint256)
    {
        // setup local rID
        uint256 _rID = rID_;

        return
        (              
              rndTmEth_[_rID][1].cosd,
              rndTmEth_[_rID][1].cosc,
              rndTmEth_[_rID][2].cosd,
              rndTmEth_[_rID][2].cosc
        );
    }

   
    function buyCore(uint256 _pID, uint256 _affID, uint256 _eth, bytes32 _keyType)
    private
    returns(uint256)
    {
        uint256 _keys;
        // if eth left is greater than min eth allowed (sorry no pocket lint)
        if (_eth > 1000000000)
        {
            // require(_eth >= getBuyPrice());
            // mint the new keys
            _keys = _eth.keysRec(getBuyPrice());
            // pay 2% out to community rewards
            uint256 _aff;
            uint256 _com;
            uint256 _holders;
            uint256 _self;

            if (_keyType == "cosd") {
                _aff        = _keys.mul(fees_[0].aff)/100;
                _com        = _keys.mul(fees_[0].com)/100;
                _holders    = _keys.mul(fees_[0].holders)/100;
                _self       = _keys.sub(_aff).sub(_com).sub(_holders);
            }else{
                _aff        = _keys.mul(fees_[2].aff)/100;
                _com        = _keys.mul(fees_[2].com)/100;
                _holders    = _keys.mul(fees_[2].holders)/100;
                _self       = _keys.sub(_aff).sub(_com).sub(_holders);
            }

            // // if they bought at least 1 whole key
            // if (_keys >= 1)
            // {
            //     // set new leaders
            //     if (round_[_rID].plyr != _pID)
            //         round_[_rID].plyr = _pID;
            //     if (round_[_rID].team != _team)
            //         round_[_rID].team = _team;
            // }
            // update player
            if(_keyType == "cosd"){

                uint256 _hldCosd;
                for (uint256 i = 1; i <= plyNum_; i++) {
                    if(i!=_pID && plyr_[i].cosd>0) _hldCosd = _hldCosd.add(plyr_[i].cosd);
                }

                // plyrRnds_[_pID][_rID].cosd   = plyrRnds_[_pID][_rID].cosd.add(_self);
                // plyrRnds_[0][_rID].cosd      = plyrRnds_[0][_rID].cosd.add(_com);     //给团队
                // plyrRnds_[_affID][_rID].cosd = plyrRnds_[_affID][_rID].cosd.add(_aff);
                //Player
                plyr_[_pID].cosd = plyr_[_pID].cosd + _self;
                plyr_[pIDCom_].cosd = plyr_[pIDCom_].cosd.add(_com);
                plyr_[_affID].affVltCosd = plyr_[_affID].affVltCosd.add(_aff);

                for (uint256 j = 1; j <= plyNum_; j++) {
                    if(j!=_pID && plyr_[j].cosd>0) {
                        // plyrRnds_[j][_rID].cosd = plyrRnds_[j][_rID].cosd.add(_holders.div(_otherHodles));
                        plyr_[j].hldVltCosd = plyr_[j].hldVltCosd.add(_holders.mul(plyr_[j].cosd).div(_hldCosd));
                        emit F3Devents.onRecHldVltCosd
                        (
                            msg.sender,
                            plyr_[j].name,
                            plyr_[j].hldVltCosd
                        );
                    }
                }
                //team
                // rndTmEth_[_rID][_team].cosd = _self.add(rndTmEth_[_rID][_team].cosd);
                // cosdNum_ = cosdNum_.add(_keys);
            }
            else{//cosc
                // plyrRnds_[_pID][_rID].cosc   = plyrRnds_[_pID][_rID].cosc.add(_self);
                // plyrRnds_[0][_rID].cosc      = plyrRnds_[0][_rID].cosc.add(_com);     //给团队
                // plyrRnds_[_affID][_rID].cosc = plyrRnds_[_affID][_rID].cosc.add(_aff);
                //Player
                plyr_[_pID].cosc = plyr_[_pID].cosc + _self;
                plyr_[pIDCom_].cosc = plyr_[0].cosc.add(_com);
                plyr_[_affID].affVltCosc = plyr_[_affID].affVltCosc.add(_aff);
                // rndTmEth_[_rID][_team].cosc = _self.add(rndTmEth_[_rID][_team].cosc);
                // coscNum_ = coscNum_.add(_keys);
            }

            keyNum_ = keyNum_.add(_keys);//update
            // plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);

            // // update round
            // if(_keyType == "cosd")
            //     round_[_rID].cosd = _keys.add(round_[_rID].cosd);
            // else
            //     round_[_rID].cosc = _keys.add(round_[_rID].cosc);

            // round_[_rID].eth = _eth.add(round_[_rID].eth);
            // rndTmEth_[_rID][_team].eth = _eth.add(rndTmEth_[_rID][_team].eth);
            // plyrRnds_[_pID][_rID].team = _team;

            // call end tx function to fire end tx event.
        //    endTx(_pID, _team, _eth, _keys, _keyType,_eventData_);

            // uint256 _now = now;
            // if (_now > round_[_rID].strt + rndGap_ && _now <= round_[_rID].strt + rndFirst_) { //first step
            //     plyrRnds_[_pID][_rID].first = plyrRnds_[_pID][_rID].first.add(_eth);
            // }
            // emit F3Devents.onBuyAndDistribute
            //     (
            //         msg.sender,
            //         plyr_[_pID].name,
            //         plyr_[_pID].cosd,
            //         plyr_[_pID].cosc,
            //         plyr_[pIDCom_].cosd,
            //         plyr_[pIDCom_].cosc,
            //         plyr_[_affID].affVltCosd,
            //         plyr_[_affID].affVltCosc,
            //         keyNum_
            //     );
        }

        return _keys;
    }  


   
    function sellKeys(uint256 _pID_, uint256 _keys_, bytes32 _keyType)
    isActivated()
    isHuman()
    // isWithinLimits(msg.value)
    public
    // payable
    returns(uint256)
    {
        uint256 _pID = _pID_;
        uint256 _keys = _keys_;
        require(_keys>0);
        uint256 _eth;

        // uint256 _aff;
        // uint256 _com;
        uint256 _holders;
        uint256 _self;
        if (_keyType == "cosd") {
                // _aff        = _keys.mul(fees_[1].aff)/100;
                // _com        = _keys.mul(fees_[1].com)/100;
                _holders    = _keys.mul(fees_[1].holders)/100;
                // _self       = _keys.sub(_aff).sub(_com);
                _self       = _self.sub(_holders);
        }else{
                // _aff        = _keys.mul(fees_[3].aff)/100;
                // _com        = _keys.mul(fees_[3].com)/100;
                _holders    = _keys.mul(fees_[3].holders)/100;
                // _self       = _keys.sub(_aff).sub(_com);
                _self       = _self.sub(_holders);
        }
        //split
       if(_keyType == "cosd"){
            require(plyr_[_pID].cosd >= _keys,"Do not have cosd!");

            uint256 _hldCosd;
                for (uint256 i = 1; i <= plyNum_; i++) {
                    if(i!=_pID && plyr_[i].cosd>0) _hldCosd = _hldCosd.add(plyr_[i].cosd);
                }

                plyr_[_pID].cosd = plyr_[_pID].cosd.sub(_self);

                for (uint256 j = 1; j <= plyNum_; j++) {
                    if(j!=_pID && plyr_[j].cosd>0) {                    
                        plyr_[j].hldVltCosd = plyr_[j].hldVltCosd.add(_holders.mul(plyr_[j].cosd).div(_hldCosd));
                        emit F3Devents.onRecHldVltCosd
                        (
                            msg.sender,
                            plyr_[j].name,
                            plyr_[j].hldVltCosd
                        );
                    }
                }
       }
       else{
            require(plyr_[_pID].cosc >= _keys,"Do not have cosc!");           

            plyr_[_pID].cosc = plyr_[_pID].cosc.sub(_self);
       }

       keyNum_ = keyNum_.sub(_keys);//update
       _eth = _keys.ethRec(getBuyPrice());

       emit F3Devents.onSellAndDistribute
                (
                    msg.sender,
                    plyr_[_pID].name,
                    plyr_[_pID].cosd,
                    plyr_[_pID].cosc,
                    keyNum_
                );

       return _eth;
    }


    function playGame(uint256 _pID, uint256 _keys, uint256 _team, bytes32 _keyType)
    isActivated()
    isHuman()
    // isWithinLimits(msg.value)
    public
    // payable
    returns(bool, bool)
    {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;
        bool _game;
        bool _end;

        // if round is active
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {   //uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, bytes32 _keyType, bytes32 F3Ddatasets.EventReturns memory _eventData_
            // call core
            _game = gameCore(_pID, _keys, _team, _keyType);

            // if round is not active
        } else {
            // check to see if end round needs to be ran
            if (_now > round_[_rID].end && round_[_rID].ended == false)
            {
                // end the round (distributes pot) & start new round
                round_[_rID].ended = true;
                // _eventData_ = endRound(_eventData_);
                uint256 _winTeam;

                _winTeam =  endRound();
                _end = true;

                // build event data
                // _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
                // _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

                // // fire buy and distribute event
                emit F3Devents.onEndRound
                (
                    rID_,
                    round_[_rID].strt,
                    round_[_rID].end,
                    round_[_rID].ended
                );
            }

        }
        return (_game, _end);
    }
  
    function gameCore(uint256 _pID, uint256 _keys, uint256 _team, bytes32 _keyType)
    private
    returns(bool)
    {
            uint256 _rID = rID_;
            uint256 _now = now;

            // update player
            if(_keyType == "cosd"){
                require(plyr_[_pID].cosd >= _keys);
                plyrRnds_[_pID][_rID].cosd   = plyrRnds_[_pID][_rID].cosd.add(_keys);
                //Player
                plyr_[_pID].cosd = plyr_[_pID].cosd.sub(_keys);
                //team
                rndTmEth_[_rID][_team].cosd = _keys.add(rndTmEth_[_rID][_team].cosd);

                if (_now > round_[_rID].strt + rndGap_ && _now <= round_[_rID].strt + rndGap_ + rndFirst_) { //first step
                    plyrRnds_[_pID][_rID].first = true;
                    plyrRnds_[_pID][_rID].redtPRFirst = 80;
                    plyrRnds_[_pID][_rID].firstCosd = plyrRnds_[_pID][_rID].firstCosd.add(_keys);
                }
            }
            else{//cosc
                require(plyr_[_pID].cosc >= _keys);
                plyrRnds_[_pID][_rID].cosc   = plyrRnds_[_pID][_rID].cosc.add(_keys);
                //Player
                plyr_[_pID].cosc = plyr_[_pID].cosc.sub(_keys);
  
                rndTmEth_[_rID][_team].cosc = _keys.add(rndTmEth_[_rID][_team].cosc);

                if (_now > round_[_rID].strt + rndGap_ && _now <= round_[_rID].strt + rndGap_ + rndFirst_) { //first step
                    plyrRnds_[_pID][_rID].first = true;
                    plyrRnds_[_pID][_rID].redtPRFirst = 80;
                    plyrRnds_[_pID][_rID].firstCosc = plyrRnds_[_pID][_rID].firstCosc.add(_keys);
                }
            }

            // update round
            if(_keyType == "cosd")
                round_[_rID].cosd = _keys.add(round_[_rID].cosd);
            else
                round_[_rID].cosc = _keys.add(round_[_rID].cosc);

            // round_[_rID].eth = _eth.add(round_[_rID].eth);
            // rndTmEth_[_rID][_team].eth = _eth.add(rndTmEth_[_rID][_team].eth);
            plyrRnds_[_pID][_rID].team = _team;

           //  call end tx function to fire end tx event.
           // endTx(_pID, _team, _eth, _keys, _keyType,_eventData_);
        //   emit F3Devents.onGameCore
        //         (
        //             msg.sender,
        //             plyr_[_pID].name,
        //             plyr_[_pID].cosd,
        //             plyr_[_pID].cosc,
        //             plyrRnds_[_pID][_rID].cosd,
        //             plyrRnds_[_pID][_rID].cosc,
        //             plyrRnds_[_pID][_rID].first,
        //             plyrRnds_[_pID][_rID].redtPRFirst,
        //             plyrRnds_[_pID][_rID].firstCosd,
        //             plyrRnds_[_pID][_rID].firstCosc,
        //             round_[_rID].cosd,
        //             round_[_rID].cosc,
        //             plyrRnds_[_pID][_rID].team
        //         );
        
            return true;
    }  

    function buyProp(uint256 _pID, uint256 _eth, uint256 _propID)
    isActivated()
    isHuman()
    // isWithinLimits(msg.value)
    public
    // payable
    returns(uint256,uint256) //pID,eth
    {
        //require(_eth <= msg.value);
        uint256 _rID = rID_;
        uint256 _rstETH = 0;
        uint256 _oID = rndProp_[_rID][_propID].oID;
        // require(_eth >= rndProp_[_rID][_propID].price && plyrRnds_[_pID][_rID].hadProp = false);

      if(_pID >= 1 && _pID <= 6){

        if (_propID == 1) {
            require(_eth >= 3 * 10**18 && plyrRnds_[_pID][_rID].hadProp == false && _oID != _pID);
            if(plyrRnds_[_pID][_rID].team == 1)
                rndTmEth_[_rID][plyrRnds_[_pID][_rID].team].winRate += 5;
            else rndTmEth_[_rID][plyrRnds_[_pID][_rID].team].winRate += 10;

            if(plyrRnds_[_pID][_rID].redtPRProp == 0) plyrRnds_[_pID][_rID].redtPRProp = 80;
            else    plyrRnds_[_pID][_rID].redtPRProp = plyrRnds_[_pID][_rID].redtPRProp*80/100;

            if(plyrRnds_[_pID][_rID].incrPRProp == 0) plyrRnds_[_pID][_rID].incrPRProp = 120;
            else    plyrRnds_[_pID][_rID].incrPRProp = plyrRnds_[_pID][_rID].incrPRProp*120/100;

            //个人亏损减少率增加，永久效果
            if(plyr_[_pID].redtProp == 0) plyr_[_pID].redtProp = 97;
            else plyr_[_pID].redtProp = plyr_[_pID].redtProp*97/100;
            //clean
            if (_oID != 0) {

                if(plyrRnds_[_oID][_rID].team == 1)
                    rndTmEth_[_rID][plyrRnds_[_oID][_rID].team].winRate -= 5;
                else rndTmEth_[_rID][plyrRnds_[_oID][_rID].team].winRate -= 10;

                plyrRnds_[_oID][_rID].redtPRProp = plyrRnds_[_oID][_rID].redtPRProp*120/100;

                plyrRnds_[_oID][_rID].incrPRProp = plyrRnds_[_oID][_rID].incrPRProp*80/100;
                //个人亏损减少率增加，永久效果
                plyr_[_oID].redtProp = plyr_[_oID].redtProp*103/100;

                plyrRnds_[_oID][_rID].hadProp = false;
                plyrRnds_[_oID][_rID].propID = 0;
            }

            rndProp_[_rID][_propID].oID = _pID;
            plyrRnds_[_pID][_rID].hadProp = true;
            plyrRnds_[_pID][_rID].propID = _propID;
            //update price
            if (_oID == 0) {
                rndProp_[_rID][_propID].price = 3 * 10**18;
                _rstETH = 0;
            }else{
                _rstETH = rndProp_[_rID][_propID].price*150/100;
                rndProp_[_rID][_propID].price = rndProp_[_rID][_propID].price*200/100;
            }
        }
        else if (_propID == 2) {
            require(_eth >= 1 * 10**18 && plyrRnds_[_pID][_rID].hadProp == false && _oID != _pID);
            if(plyrRnds_[_pID][_rID].team == 1)
                rndTmEth_[_rID][plyrRnds_[_pID][_rID].team].winRate += 2;
            else rndTmEth_[_rID][plyrRnds_[_pID][_rID].team].winRate += 4;

            if(plyrRnds_[_pID][_rID].redtPRProp == 0) plyrRnds_[_pID][_rID].redtPRProp = 90;
            else    plyrRnds_[_pID][_rID].redtPRProp = plyrRnds_[_pID][_rID].redtPRProp*90/100;
            //个人亏损减少率增加，永久效果
            if(plyr_[_pID].redtProp == 0) plyr_[_pID].redtProp = 99;
            else plyr_[_pID].redtProp = plyr_[_pID].redtProp*99/100;
            //clean
            if (_oID != 0) {

                if(plyrRnds_[_oID][_rID].team == 1)
                    rndTmEth_[_rID][plyrRnds_[_oID][_rID].team].winRate -= 2;
                else rndTmEth_[_rID][plyrRnds_[_oID][_rID].team].winRate -= 4;

                plyrRnds_[_oID][_rID].redtPRProp = plyrRnds_[_oID][_rID].redtPRProp*110/100;
                //个人亏损减少率增加，永久效果
                plyr_[_oID].redtProp = plyr_[_oID].redtProp*101/100;

                plyrRnds_[_oID][_rID].hadProp = false;
                plyrRnds_[_oID][_rID].propID = 0;
            }

            rndProp_[_rID][_propID].oID = _pID;
            plyrRnds_[_pID][_rID].hadProp = true;
            plyrRnds_[_pID][_rID].propID = _propID;
            //update price
            if (_oID == 0) {
                rndProp_[_rID][_propID].price = 1 * 10**18;
                _rstETH = 0;
            }else{
                _rstETH = rndProp_[_rID][_propID].price*200/100;
                rndProp_[_rID][_propID].price = rndProp_[_rID][_propID].price*300/100;
            }
        }
        else if (_propID == 3) {
            require(_eth >= 1 * 10**18 && plyrRnds_[_pID][_rID].hadProp == false && _oID != _pID);
            if(plyrRnds_[_pID][_rID].team == 1)
                rndTmEth_[_rID][plyrRnds_[_pID][_rID].team].winRate += 2;
            else rndTmEth_[_rID][plyrRnds_[_pID][_rID].team].winRate += 4;

            if(plyrRnds_[_pID][_rID].incrPRProp == 0) plyrRnds_[_pID][_rID].incrPRProp = 110;
            else    plyrRnds_[_pID][_rID].incrPRProp = plyrRnds_[_pID][_rID].incrPRProp*110/100;
            //个人亏损减少率增加，永久效果
            if(plyr_[_pID].redtProp == 0) plyr_[_pID].redtProp = 99;
            else plyr_[_pID].redtProp = plyr_[_pID].redtProp*99/100;
            //clean
            if (_oID != 0) {

                if(plyrRnds_[_oID][_rID].team == 1)
                    rndTmEth_[_rID][plyrRnds_[_oID][_rID].team].winRate -= 2;
                else rndTmEth_[_rID][plyrRnds_[_oID][_rID].team].winRate -= 4;

                plyrRnds_[_oID][_rID].incrPRProp = plyrRnds_[_oID][_rID].incrPRProp*90/100;
                //个人亏损减少率增加，永久效果
                plyr_[_oID].redtProp = plyr_[_oID].redtProp*101/100;

                plyrRnds_[_oID][_rID].hadProp = false;
                plyrRnds_[_oID][_rID].propID = 0;
            }

            rndProp_[_rID][_propID].oID = _pID;
            plyrRnds_[_pID][_rID].hadProp = true;
            plyrRnds_[_pID][_rID].propID = _propID;
            //update price
            if (_oID == 0) {
                rndProp_[_rID][_propID].price = 1 * 10**18;
                _rstETH = 0;
            }else{
                _rstETH = rndProp_[_rID][_propID].price*200/100;
                rndProp_[_rID][_propID].price = rndProp_[_rID][_propID].price*300/100;
            }
        }
        else if (_propID == 4) {
            require(_eth >= 5 * 10**17 && plyrRnds_[_pID][_rID].hadProp == false && _oID != _pID);
            if(plyrRnds_[_pID][_rID].team == 1)
                rndTmEth_[_rID][plyrRnds_[_pID][_rID].team].winRate += 1;
            else rndTmEth_[_rID][plyrRnds_[_pID][_rID].team].winRate += 2;

            if(plyrRnds_[_pID][_rID].redtPRProp == 0) plyrRnds_[_pID][_rID].redtPRProp = 90;
            else    plyrRnds_[_pID][_rID].redtPRProp = plyrRnds_[_pID][_rID].redtPRProp*90/100;

            //个人亏损减少率增加，永久效果
            if(plyr_[_pID].redtProp == 0) plyr_[_pID].redtProp = 99;
            else plyr_[_pID].redtProp = plyr_[_pID].redtProp*995/1000;
            //clean
            if (_oID != 0) {

                if(plyrRnds_[_oID][_rID].team == 1)
                    rndTmEth_[_rID][plyrRnds_[_oID][_rID].team].winRate -= 1;
                else rndTmEth_[_rID][plyrRnds_[_oID][_rID].team].winRate -= 2;

                plyrRnds_[_oID][_rID].redtPRProp = plyrRnds_[_oID][_rID].redtPRProp*110/100;
                //个人亏损减少率增加，永久效果
                plyr_[_oID].redtProp = plyr_[_oID].redtProp*1005/1000;

                plyrRnds_[_oID][_rID].hadProp = false;
                plyrRnds_[_oID][_rID].propID = 0;
            }

            rndProp_[_rID][_propID].oID = _pID;
            plyrRnds_[_pID][_rID].hadProp = true;
            plyrRnds_[_pID][_rID].propID = _propID;
            //update price
            if (_oID == 0) {
                rndProp_[_rID][_propID].price = 5 * 10**17;
                _rstETH = 0;
            }else{
                _rstETH = rndProp_[_rID][_propID].price*250/100;
                rndProp_[_rID][_propID].price = rndProp_[_rID][_propID].price*400/100;
            }
        }
        else if (_propID == 5) {
            require(_eth >= 5 * 10**17 && plyrRnds_[_pID][_rID].hadProp == false && _oID != _pID);
            if(plyrRnds_[_pID][_rID].team == 1)
                rndTmEth_[_rID][plyrRnds_[_pID][_rID].team].winRate += 1;
            else rndTmEth_[_rID][plyrRnds_[_pID][_rID].team].winRate += 2;

            if(plyrRnds_[_pID][_rID].incrPRProp == 0) plyrRnds_[_pID][_rID].incrPRProp = 110;
            else    plyrRnds_[_pID][_rID].incrPRProp = plyrRnds_[_pID][_rID].incrPRProp*110/100;
            //个人亏损减少率增加，永久效果
            if(plyr_[_pID].redtProp == 0) plyr_[_pID].redtProp = 99;
            else plyr_[_pID].redtProp = plyr_[_pID].redtProp*995/1000;
            //clean
            if (_oID != 0) {

                if(plyrRnds_[_oID][_rID].team == 1)
                    rndTmEth_[_rID][plyrRnds_[_oID][_rID].team].winRate -= 1;
                else rndTmEth_[_rID][plyrRnds_[_oID][_rID].team].winRate -= 2;

                plyrRnds_[_oID][_rID].incrPRProp = plyrRnds_[_oID][_rID].incrPRProp*90/100;
                //个人亏损减少率增加，永久效果
                plyr_[_oID].redtProp = plyr_[_oID].redtProp*1005/1000;

                plyrRnds_[_oID][_rID].hadProp = false;
                plyrRnds_[_oID][_rID].propID = 0;
            }

            rndProp_[_rID][_propID].oID = _pID;
            plyrRnds_[_pID][_rID].hadProp = true;
            plyrRnds_[_pID][_rID].propID = _propID;
            //update price
            if (_oID == 0) {
                rndProp_[_rID][_propID].price = 5 * 10**17;
                _rstETH = 0;
            }else{
                _rstETH = rndProp_[_rID][_propID].price*250/100;
                rndProp_[_rID][_propID].price = rndProp_[_rID][_propID].price*400/100;
            }
        }
        //imit
        if(plyrRnds_[_pID][_rID].redtPRProp < 80) plyrRnds_[_pID][_rID].redtPRProp = 80;
        if(plyrRnds_[_pID][_rID].incrPRProp > 120) plyrRnds_[_pID][_rID].incrPRProp = 120;
        //个人亏损减少率增加，永久效果
        if(plyr_[_pID].redtProp < 90) plyr_[_pID].redtProp = 90;

        if(plyrRnds_[_oID][_rID].redtPRProp < 80) plyrRnds_[_oID][_rID].redtPRProp = 80;
        if(plyrRnds_[_oID][_rID].incrPRProp > 120) plyrRnds_[_oID][_rID].incrPRProp = 120;
        //个人亏损减少率增加，永久效果
        if(plyr_[_oID].redtProp < 90) plyr_[_oID].redtProp = 90;
 
      }
    //   emit F3Devents.onBuyProp
    //             (
    //                 msg.sender,
    //                 plyr_[_pID].name,
    //                 plyrRnds_[_pID][_rID].redtPRProp,
    //                 plyrRnds_[_pID][_rID].incrPRProp,
    //                 plyr_[_pID].redtProp,
    //                 plyrRnds_[_pID][_rID].hadProp,
    //                 plyrRnds_[_pID][_rID].propID,
    //                 plyrRnds_[_oID][_rID].redtPRProp,
    //                 plyrRnds_[_oID][_rID].incrPRProp,
    //                 plyr_[_oID].redtProp,
    //                 plyrRnds_[_oID][_rID].hadProp,
    //                 plyrRnds_[_oID][_rID].propID,
    //                 rndProp_[_rID][_propID].oID
    //             );

      return (_oID,_rstETH);
    }

    function buyLeader(uint256 _pID, uint256 _eth)
    isActivated()
    isHuman()
    // isWithinLimits(msg.value)
    public
    // payable
    returns(uint256,uint256)
    {
        uint256 _rID = rID_;
        uint256 _oID = rndLd_[_rID].oID;
        uint256 _rstETH = 0;

        require(_eth >= 1 * 10**18 && _oID != _pID);
        
        if (_oID == 0) {
            _rstETH = 0;
            rndLd_[_rID].price = 1 * 10**18;
        }
        else{//clean
            if(plyrRnds_[_oID][_rID].team == 1)
                    rndTmEth_[_rID][plyrRnds_[_oID][_rID].team].winRate -= 4;
            else    rndTmEth_[_rID][plyrRnds_[_oID][_rID].team].winRate -= 8;

            _rstETH = rndLd_[_rID].price*110/100;
            rndLd_[_rID].price = rndLd_[_rID].price*120/100;
        }

        if(plyrRnds_[_pID][_rID].team == 1)
                    rndTmEth_[_rID][plyrRnds_[_pID][_rID].team].winRate += 4;
        else        rndTmEth_[_rID][plyrRnds_[_pID][_rID].team].winRate += 8;
            //set leader    
        round_[_rID].plyr = _pID;
        round_[_rID].team = plyrRnds_[_pID][_rID].team;
        uint256 _team = plyrRnds_[_pID][_rID].team;

        emit F3Devents.onBuyLeader
        (
            msg.sender,
            rndLd_[_rID].price,
            round_[_rID].plyr,
            round_[_rID].team,
            rndTmEth_[_rID][_team].winRate,
            rndTmEth_[_rID][_team].winRate
        );

        return(_oID,_rstETH);
    }
   
    function iWantXKeys(uint256 _keys)
    public
    // view
    returns(uint256)
    {
        // // setup local rID
        // uint256 _rID = rID_;

        // // grab time
        // uint256 _now = now;

        // // are we in a round?
        // if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        //     return ( _keys.ethRec(getBuyPrice()) );
        // else // rounds over.  need price for new round
            return ( _keys.ethRec(getBuyPrice()) );
    }
    //==============================================================================
    //    _|_ _  _ | _  .
    //     | (_)(_)|_\  .
    // //==============================================================================
    // 
    //  @dev receives name/player info from names contract
    //  
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

    //  **
    //  * @dev receives entire player name list
    //  *
    function receivePlayerNameList(uint256 _pID, bytes32 _name)
    external
    {
        require (msg.sender == address(PlayerBook), "your not playerNames contract... hmmm..");
        if(plyrNames_[_pID][_name] == false)
            plyrNames_[_pID][_name] = true;
    }

    // **
    //  * @dev gets existing or registers new pID.  use this when a player may be new
    //  * @return pID
    //  *
    function determinePID()
    private
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
            // _eventData_.compressedData = _eventData_.compressedData + 1;
            plyNum_++;
        }
        // return (_eventData_);
    }

    //  **
    //  * @dev checks to make sure user picked a valid team.  if not sets team
    //  * to default (sneks)
    //  *
    function verifyTeam(uint256 _team)
    private
    pure
    returns (uint256)
    {
        if (_team < 1 || _team > 2)
            return(1);
        else
            return(_team);
    }

    //  **
    //  * @dev decides if round end needs to be run & new round started.  and if
    //  * player unmasked earnings from previously played rounds need to be moved.
    //  *
    // function managePlayer(uint256 _pID, F3Ddatasets.EventReturns memory _eventData_)
    // private
    // returns (F3Ddatasets.EventReturns memory)
    // {
    //     // update player&#39;s last round played
    //     plyr_[_pID].lrnd = rID_;

    //     // set the joined round bool to true
    //     _eventData_.compressedData = _eventData_.compressedData + 10;

    //     return(_eventData_);
    // }

    //  **
    //  * @dev ends the round. manages paying out winner/splitting up pot
    //  *
    
    function endRound()
    private
    returns (uint256)
    {
        // setup local rID
        uint256 _rID = rID_;
        // uint256 _rID = _rID_;

        uint256 _ramNum = F3DKeysCalcLong.random();
        uint256 _winTeam;
        uint256 i;

        for ( i = 1; i <= plyNum_; i++) {

            if (plyrRnds_[i][_rID].incrPRProp > 0) {
                plyrRnds_[i][_rID].cosd = plyrRnds_[i][_rID].cosd.mul(plyrRnds_[i][_rID].incrPRProp).div(100);
                plyrRnds_[i][_rID].cosc = plyrRnds_[i][_rID].cosc.mul(plyrRnds_[i][_rID].incrPRProp).div(100);
            }

            if (plyrRnds_[i][_rID].cosd.add(plyrRnds_[i][_rID].cosc) > threshould_) {
                plyr_[i].rounds++;
                //update ret
                if(plyr_[i].redt1 == 0) plyr_[i].redt1 = 99;
                else plyr_[i].redt1 = plyr_[i].redt1 * 995 / 1000;

                if (plyr_[i].rounds % 4 == 0) {
                    if(plyr_[i].redt3 == 0) plyr_[i].redt3 = 90;
                    else plyr_[i].redt3 = plyr_[i].redt3 * 90 / 100;
                }
                //limit
                if(plyr_[i].redt1 < 90) plyr_[i].redt1 = 90;
                if(plyr_[i].redt3 < 90) plyr_[i].redt3 = 90;
            }

            emit F3Devents.onEndRoundProssRate
                (
                    msg.sender,
                    plyr_[i].name,
                    plyrRnds_[i][_rID].cosd,
                    plyrRnds_[i][_rID].cosc,
                    plyr_[i].rounds,
                    plyr_[i].redt1,
                    plyr_[i].redt3
                );

        }


        if ( _ramNum <= (rndTmEth_[_rID][1].winRate + 70) )
            _winTeam = 1;
    
        else _winTeam = 2;
        

        prossWinOrLoss(_winTeam);

        round_[_rID].winTeam = _winTeam;
        // prepare event data
        // _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
        // _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * 100000000000000000000000000) + (_winTID * 100000000000000000);

        // start next round
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_).add(rndGap_);
        // update player&#39;s last round played
        // plyr_[_pID].lrnd = rID_;

        return (_winTeam);
    }
 
    function prossWinOrLoss(uint256 _winTeam)
    private
    returns(bool){
        uint256 i;
        uint256 _ttlCosd;
        uint256 _ttlCosc;
        uint256 _rID = rID_;
        uint256 _lossCosd;
        uint256 _lossCosc;

        uint256    _potCosd = rndTmEth_[_rID][1].cosd.add(rndTmEth_[_rID][2].cosd);
        uint256    _potCosc = rndTmEth_[_rID][1].cosc.add(rndTmEth_[_rID][2].cosc);
        //com

            plyr_[pIDCom_].cosd = plyr_[pIDCom_].cosd.add(_potCosd * 3 / 100);
            plyr_[pIDCom_].cosc = plyr_[pIDCom_].cosc.add(_potCosc * 3 / 100);

            _potCosd = _potCosd.sub(_potCosd * 97 / 100);
            _potCosc = _potCosc.sub(_potCosd * 97 / 100);

            for ( i = 1; i <= plyNum_; i++) {
                if (i != 0 && plyrRnds_[i][_rID].team == _winTeam) {//赢的队伍
                    _ttlCosd = _ttlCosd.add(plyrRnds_[i][_rID].cosd);
                    _ttlCosc = _ttlCosc.add(plyrRnds_[i][_rID].cosc);
                }
            }

            for ( i=1 ; i <= plyNum_; i++) {
                if (i != 0 && plyrRnds_[i][_rID].team != _winTeam) {//输的
                    _lossCosd = plyrRnds_[i][_rID].cosd;
                    _lossCosc = plyrRnds_[i][_rID].cosc;

                    if (plyrRnds_[i][_rID].redtPRProp > 0) {
                        _lossCosd = _lossCosd*plyrRnds_[i][_rID].redtPRProp/100;
                        _lossCosc = _lossCosc*plyrRnds_[i][_rID].redtPRProp/100;
                    }
                    if (plyr_[i].redt1 > 0) {
                        _lossCosd = _lossCosd*plyr_[i].redt1/100;
                        _lossCosc = _lossCosc*plyr_[i].redt1/100;
                    }
                    if (plyr_[i].redt3 > 0) {
                        _lossCosd = _lossCosd*plyr_[i].redt3/100;
                        _lossCosc = _lossCosc*plyr_[i].redt3/100;
                    }
                    if (plyrRnds_[i][_rID].redtPRFirst > 0) {
                        _lossCosd = _lossCosd.add(plyrRnds_[i][_rID].firstCosd * plyrRnds_[i][_rID].redtPRFirst / 100);
                        _lossCosc = _lossCosc.add(plyrRnds_[i][_rID].firstCosc * plyrRnds_[i][_rID].redtPRFirst / 100);
                    }
                    plyrRnds_[i][_rID].wonCosd = plyrRnds_[i][_rID].cosd.sub(_lossCosd);
                    plyrRnds_[i][_rID].wonCosc = plyrRnds_[i][_rID].cosc.sub(_lossCosc);

                    _potCosd = _potCosd - plyrRnds_[i][_rID].wonCosd;
                    _potCosc = _potCosc - plyrRnds_[i][_rID].wonCosc;

                    plyr_[i].lrnd = _rID;

                    emit F3Devents.onLoss
                    (
                        msg.sender,
                        plyr_[i].name,
                        plyrRnds_[i][_rID].wonCosd,
                        plyrRnds_[i][_rID].wonCosc,
                        plyr_[i].lrnd
                    );
                }
            }

            for ( i=1 ; i <= plyNum_; i++) {
                if (plyrRnds_[i][_rID].team == _winTeam) {//赢的队伍
                    plyrRnds_[i][_rID].wonCosd = plyrRnds_[i][_rID].wonCosd.add(_potCosd.mul(plyrRnds_[i][_rID].cosd).div(_ttlCosd));
                    plyrRnds_[i][_rID].wonCosc = plyrRnds_[i][_rID].wonCosc.add(_potCosc.mul(plyrRnds_[i][_rID].cosc).div(_ttlCosc));
                    plyr_[i].lrnd = _rID;

                    emit F3Devents.onWin
                    (
                        msg.sender,
                        plyr_[i].name,
                        plyrRnds_[i][_rID].wonCosd,
                        plyrRnds_[i][_rID].wonCosc,
                        plyr_[i].lrnd
                    );
                }
            }

            return true;
    }

    function withdrawHoldVault(uint256 _pID)
    public
    returns(bool){
        if (plyr_[_pID].hldVltCosd>0) {
            plyr_[_pID].cosd = plyr_[_pID].cosd.add(plyr_[_pID].hldVltCosd);
            plyr_[_pID].hldVltCosd = 0;
        }

        emit F3Devents.onWithdrawHoldVault
                    (
                        _pID,
                        msg.sender,
                        plyr_[_pID].name,
                        plyr_[_pID].cosd,
                        plyr_[_pID].hldVltCosd
                    );

        return true;
    }

    function withdrawAffVault(uint256 _pID)
    public
    returns(bool){
        if (plyr_[_pID].affVltCosd>0) {
            plyr_[_pID].cosd = plyr_[_pID].cosd.add(plyr_[_pID].affVltCosd);
            plyr_[_pID].affVltCosd = 0;
        }
        if (plyr_[_pID].affVltCosc>0) {
            plyr_[_pID].cosc = plyr_[_pID].cosc.add(plyr_[_pID].affVltCosc);
            plyr_[_pID].affVltCosc = 0;
        }

                emit F3Devents.onWithdrawAffVault
                    (
                        _pID,
                        msg.sender,
                        plyr_[_pID].name,
                        plyr_[_pID].cosd,
                        plyr_[_pID].cosc,
                        plyr_[_pID].affVltCosd,
                        plyr_[_pID].affVltCosc
                    );

        return true;
    }

    function withdrawWonCosFromGame(uint256 _pID, uint256 _affID, uint256 _rID)//一轮只能提取一次
    public
    returns(bool){
        // uint256 _rID = rID_;
        uint256 _aff;
        uint256 _holders;
        uint256 _self;
    
        if (plyrRnds_[_pID][_rID].wonCosd > 0) {

                uint256 _hldCosd;
                for (uint256 i = 1; i <= plyNum_; i++) {
                    if(i!=_pID && plyr_[i].cosd>0) _hldCosd = _hldCosd.add(plyr_[i].cosd);
                }

                _holders = plyrRnds_[_pID][_rID].wonCosd * 5/100;
                _aff =     plyrRnds_[_pID][_rID].wonCosd * 1/100;
                _self = plyrRnds_[_pID][_rID].wonCosd.sub(_holders).sub(_aff);

                plyr_[_pID].cosd = plyr_[_pID].cosd.add(_self);
                plyr_[_affID].affVltCosd = plyr_[_affID].affVltCosd.add(_aff);

                for (uint256 j = 1; j <= plyNum_; j++) {
                    if(j!=_pID && plyr_[j].cosd>0) plyr_[j].hldVltCosd = plyr_[j].hldVltCosd.add(_holders.mul(plyr_[j].cosd).div(_hldCosd));
                }

                plyrRnds_[_pID][_rID].wonCosdRcd = plyrRnds_[_pID][_rID].wonCosd;
                plyrRnds_[_pID][_rID].wonCosd = 0;
        }

        if (plyrRnds_[_pID][_rID].wonCosc > 0) {
            plyr_[_pID].cosc = plyr_[_pID].cosc.add(plyrRnds_[_pID][_rID].wonCosc);

            plyrRnds_[_pID][_rID].wonCoscRcd = plyrRnds_[_pID][_rID].wonCosc;
            plyrRnds_[_pID][_rID].wonCosc = 0;
        }

        // emit F3Devents.onWithdrawWonCosFromGame
        //             (
        //                 _pID,
        //                 msg.sender,
        //                 plyr_[i].name,
        //                 plyr_[_pID].cosd,
        //                 plyr_[_pID].cosc,
        //                 plyr_[_pID].affVltCosd
        //             );

        return true;
    }

    function transferToAnotherAddr(address _to, uint256 _keys, bytes32 _keyType)
    public
    returns(bool){
        // uint256 _rID = rID_;
        uint256 _holders;
        uint256 _self;
        uint256 i;

        determinePID();
        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 _tID = pIDxAddr_[_to];

        require(_tID > 0);
    
        if (_keyType == "cosd") {

                require(plyr_[_pID].cosd >= _keys);

                uint256 _hldCosd;
                for ( i = 1; i <= plyNum_; i++) {
                    if(i!=_pID && plyr_[i].cosd>0) _hldCosd = _hldCosd.add(plyr_[i].cosd);
                }

                _holders = _keys * 20/100;
                // _aff =     plyrRnds_[_pID][_rID].wonCosd * 1/100;
                _self = plyr_[_pID].cosd.sub(_holders);

                plyr_[_tID].cosd = plyr_[_tID].cosd.add(_self);
                plyr_[_pID].cosd = plyr_[_pID].cosd.sub(_self);

                for ( i = 1; i <= plyNum_; i++) {
                    if(i!=_pID && plyr_[i].cosd>0) plyr_[i].hldVltCosd = plyr_[i].hldVltCosd.add(_holders.mul(plyr_[i].cosd).div(_hldCosd));
                }
        }

        else{
            require(plyr_[_pID].cosc >= _keys);

            plyr_[_tID].cosc = plyr_[_tID].cosc.add(_keys);
            plyr_[_pID].cosc = plyr_[_pID].cosc.sub(_keys);
        }

        // emit F3Devents.onWithdrawWonCosFromGame
        //             (
        //                 _pID,
        //                 msg.sender,
        //                 plyr_[i].name,
        //                 plyr_[_pID].cosd,
        //                 plyr_[_pID].cosc,
        //                 plyr_[_pID].affVltCosd
        //             );

        return true;
    }
    
    //==============================================================================
    //    (~ _  _    _._|_    .
    //    _)(/_(_|_|| | | \/  .
    //====================/=========================================================
    // ** upon contract deploy, it will be deactivated.  this is a one time
    //  * use function that will activate the contract.  we do this so devs
    //  * have time to set things up on the web end                            **
    bool public activated_ = false;
    function activate()
    public onlyOwner {
        // make sure that its been linked.
        //        require(address(otherF3D_) != address(0), "must link to other FoMo3D first");

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
    // struct EventReturns {
    //     uint256 compressedData;
    //     uint256 compressedIDs;
    //     address winnerAddr;         // winner address
    //     bytes32 winnerName;         // winner name
    //     uint256 amountWonCosd;          // amount won
    //     uint256 amountWonCosc;          // amount won
    // }
    struct Player {
        address addr;   // player address
        bytes32 name;   // player name
        uint256 cosd;    // winnings vault
        uint256 cosc;    // winnings vault
        uint256 lrnd;   // last round played
        uint256 laff;   // last affiliate id used
        uint256 rounds; //超过xxxcosd的轮数累计
        uint256 redtProp; //买道具赠送的累计亏损减少率
        uint256 redt1;
        uint256 redt3;
        uint256 affVltCosd;
        uint256 affVltCosc;
        uint256 hldVltCosd;
    }
    struct PlayerRounds {
        uint256 cosd;   // keys
        uint256 cosc;   // keys
        bool hadProp;
        uint256 propID;
        uint256 redtPRProp; //lossReductionRate，玩家当前回合道具总亏损减少率
        uint256 incrPRProp; //Income increase rate收入增加率
        uint256 team;
        bool first;
        uint256 firstCosd;//第一阶段投入的COS资金，可减少20% 亏损率
        uint256 firstCosc;//第一阶段投入的COS资金，可减少20% 亏损率
        uint256 redtPRFirst;
        uint256 wonCosd;
        uint256 wonCosc;
        uint256 wonCosdRcd;
        uint256 wonCoscRcd;
    }
    struct Round {
        uint256 plyr;   // pID of player in lead
        uint256 team;   // tID of team in lead
        uint256 end;    // time ends/ended
        bool ended;     // has round end function been ran
        uint256 strt;   // time round started
        uint256 cosd;   // keys
        uint256 cosc;   // keys
        uint256 winTeam;
    }     
    struct Team {
        uint256 teamID;        
        uint256 winRate;    // 胜率
        uint256 eth;
        uint256 cosd;
        uint256 cosc;
    }
    struct Prop {           //道具
        uint256 propID;         
        uint256 price;
        uint256 oID;
    }
    struct Leader {           //道具       
        uint256 price;
        uint256 oID;
    }
    struct Fee {
        uint256 aff;          // % of buy in thats paid to referrer  of current round推荐人分配比例
        uint256 com;    // % of buy in thats paid for comnunity
        uint256 holders; //key holders
    }
}

library F3DKeysCalcLong {
    using SafeMath for *;

    function keysRec(uint256 _newEth, uint256 _price)
    internal
    pure
    returns (uint256)
    {
        return( keys(_newEth, _price) );
    }

    function ethRec(uint256 _sellKeys, uint256 _price)
    internal
    pure
    returns (uint256)
    {
        return ( eth(_sellKeys, _price) );
    }

    function keys(uint256 _eth, uint256 _price)
    internal
    pure
    returns(uint256)
    {
        uint256 _rstAmount;
        // require(_price >= 10**16);
        // require(_eth >= msg.value);

        while(_eth >= _price){
            _eth = _eth - _price;
            _price = _price + _price*3/10000;
            _rstAmount++;
        }

        return _rstAmount;
    }

    function eth(uint256 _keys, uint256 _price)
    internal
    pure
    returns(uint256)
    {
        uint256 _eth = 0;
        // require(_price >= 10**16);
        // require(_eth >= msg.value);

        while(_keys > 0){
            _eth = _eth + _price;
            _price = _price - _price*3/10000;
            _keys--;
        }

        return _eth;
    }

    function random() internal pure returns (uint256) {
       uint ranNum = uint(keccak256(msg.data)) % 100;
       return ranNum;
   }
}

contract FoMo3DProxy {
    //    otherFoMo3D private otherF3D_;
    // FoMo3DLongInterface  private foMo3DLong = FoMo3DLongInterface(this);

     //==============================================================================
    //     _ _  _  |`. _     _ _ |_ | _  _  .
    //    (_(_)| |~|~|(_||_|| (_||_)|(/__\  .  (game settings)
    //=================_|===========================================================
    string constant public name = "FoMo3D Proxy";
    string constant public symbol = "F3DP";
    FoMo3DLong foMo3DLong;

    constructor()
    public
    {
        foMo3DLong = FoMo3DLong(this);
    }

    function buyXid(uint256 _affCode, uint256 _eth, bytes32 _keyType) public returns(uint256){
        return foMo3DLong.buyXid(_affCode, _eth, _keyType);
    }
    function buyXaddr(address _affCode, uint256 _eth, bytes32 _keyType) public returns(uint256){
        return foMo3DLong.buyXaddr(_affCode,  _eth, _keyType);
    }
    // function _buyXname(bytes32 _affCode, uint256 _eth, bytes32 _keyType) public returns(uint256){
    //     return FoMo3DLong.buyXname(_affCode,  _eth, _keyType);
    // }


    function registerNameXid(string memory _nameString, uint256 _affCode, bool _all) public{
        foMo3DLong.registerNameXid(_nameString, _affCode, _all);
    }
    function registerNameXaddr(string memory _nameString, address _affCode, bool _all) public{
        foMo3DLong.registerNameXaddr(_nameString, _affCode, _all);
    }
    // function _registerNameXname(string memory _nameString, bytes32 _affCode, bool _all) public{
    //     FoMo3DLong.registerNameXname(_nameString, _affCode, _all);
    // }

    
    function getBuyPrice() public returns(uint256){
        return foMo3DLong.getBuyPrice();
    }
    function getTimeLeft() public returns(uint256){
        return foMo3DLong.getTimeLeft();
    }

    function getCurrentRoundInfo() public returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256){
        return foMo3DLong.getCurrentRoundInfo();
    }
    function getPlayerInfoByAddress(address _addr) public returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256){
        return foMo3DLong.getPlayerInfoByAddress(_addr);
    }
    function getCurrentRoundTeamCos() public view returns(uint256,uint256,uint256,uint256){
        return foMo3DLong.getCurrentRoundTeamCos();
    }
    
    function sellKeys(uint256 _pID_, uint256 _keys_, bytes32 _keyType) public returns(uint256){
        return foMo3DLong.sellKeys(_pID_, _keys_, _keyType);
    }
    function playGame(uint256 _pID, uint256 _keys, uint256 _team, bytes32 _keyType) public returns(bool,bool){
        return foMo3DLong.playGame(_pID, _keys, _team, _keyType);
    }

    function buyProp(uint256 _pID, uint256 _eth, uint256 _propID) public returns(uint256,uint256){
        return foMo3DLong.buyProp(_pID, _eth,_propID);
    }
    function buyLeader(uint256 _pID, uint256 _eth) public returns(uint256,uint256){
        return foMo3DLong.buyLeader(_pID, _eth);
    }
    function iWantXKeys(uint256 _keys) public returns(uint256){
        return foMo3DLong.iWantXKeys(_keys);
    }
    
    function withdrawHoldVault(uint256 _pID) public returns(bool){
        return foMo3DLong.withdrawHoldVault(_pID);
    }
    function withdrawAffVault(uint256 _pID) public returns(bool){
        return foMo3DLong.withdrawAffVault(_pID);
    }

    function withdrawWonCosFromGame(uint256 _pID, uint256 _affID, uint256 _rID) public returns(bool){
        return foMo3DLong.withdrawWonCosFromGame(_pID, _affID, _rID);
    }

    function transferToAnotherAddr(address _to, uint256 _keys, bytes32 _keyType) public returns(bool){
        return foMo3DLong.transferToAnotherAddr(_to, _keys, _keyType);
    }

    function activate() public{
        foMo3DLong.activate();
    }

}