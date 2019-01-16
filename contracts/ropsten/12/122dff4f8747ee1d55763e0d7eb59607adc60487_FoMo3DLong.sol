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
        if (a == 0 || b == 0) {
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
        // require(b > 0);
        if(b <= 0) return 0;
        else return a / b;
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
    function nameFilter(string  _input)
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

contract FoMo3DLong is modularLong, Ownable {
    using SafeMath for *;
    using NameFilter for *;
    using F3DKeysCalcLong for *;

    //    otherFoMo3D private otherF3D_;
    PlayerBookInterface constant private PlayerBook = PlayerBookInterface(0xc567D5cBB55FD1BC95Cf9B0d3975c1ABA30A54F0);

     //==============================================================================
    //     _ _  _  |`. _     _ _ |_ | _  _  .
    //    (_(_)| |~|~|(_||_|| (_||_)|(/__\  .  (game settings)
    //=================_|===========================================================
    string constant public name = "FoMo3D World";
    string constant public symbol = "F3DW";
    //    uint256 private rndExtra_ = extSettings.getLongExtra();     // length of the very first ICO
    // uint256 constant public rndGap_ = 0; // 120 seconds;         // length of ICO phase.
    // uint256 constant public rndInit_ = 350 minutes;                // round timer starts at this
    // uint256 constant public rndShow_ = 10 minutes;                // 
    // uint256 constant private rndInc_ = 30 seconds;              // every full key purchased adds this much to the timer
    // uint256 constant private rndMax_ = 24 hours;                // max length a round timer can be

    // uint256 constant public rndFirst_ = 1 hours;                // a round fist step timer can be

    // uint256 constant public threshould_ = 10;//超过XXX个cos

    uint256 public rID_;    // round id number / total rounds that have happened
    uint256 public plyNum_ = 2;
    // uint256 public keyNum_ = 0;
    uint256 public cosdNum_ = 0;
    uint256 public coscNum_ = 0;
    uint256 public totalVolume_ = 0;
    uint256 public totalVltCosd_ = 0;
    uint256 public result_ = 0;
    uint256 public price_ = 10**16;
    uint256 public priceCntThreshould_ = 100000; 

    uint256 constant public pIDCom_ = 1;
    //****************
    // PLAYER DATA
    //****************
    mapping (address => uint256) public pIDxAddr_;          // (addr => pID) returns player id by address
    mapping (bytes32 => uint256) public pIDxName_;          // (name => pID) returns player id by name
    mapping (uint256 => F3Ddatasets.Player) public plyr_;   // (pID => data) player data
    // mapping (uint256 => mapping (uint256 => F3Ddatasets.PlayerRounds)) public plyrRnds_;    // (pID => rID => data) player round data by player id & round id
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_; // (pID => name => bool) list of names a player owns.  (used so you can change your display name amongst any name you own)
    //****************
    // ROUND DATA
    //****************
    // mapping (uint256 => F3Ddatasets.Round) public round_;   // (rID => data) round data
    // mapping (uint256 => mapping(uint256 => F3Ddatasets.Prop)) public rndProp_;      // (rID => propID => data) eth in per team, by round id and team id
    // mapping (uint256 => mapping(uint256 => F3Ddatasets.Team)) public rndTmEth_;      // (rID => tID => data) eth in per team, by round id and team id
    // mapping (uint256 => F3Ddatasets.Leader) public rndLd_;      // (rID => data) eth in per team, by round id and team id
    
    //****************
    // TEAM FEE DATA
    //****************

    // mapping (uint256 => F3Ddatasets.Team) public teams_;          // (teamID => team)
    // mapping (uint256 => F3Ddatasets.Prop) public props_;          // (teamID => team)
    // mapping (uint256 => F3Ddatasets.Fee) public fees_;          // (teamID => team)
    
    //F3Ddatasets.EventReturns  _eventData_;
    
    // fees_[0] = F3Ddatasets.Fee(5,2,3);    //cosdBuyFee
    // fees_[1] = F3Ddatasets.Fee(0,0,20);  //cosdSellFee
    // fees_[2] = F3Ddatasets.Fee(4,1,0);    //coscBuyFee
    // fees_[3] = F3Ddatasets.Fee(0,0,0);   //coscSellFee

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
        // fees_[0] = F3Ddatasets.Fee(5,2,3);    //cosdBuyFee
        // fees_[1] = F3Ddatasets.Fee(0,0,20);  //cosdSellFee
        // fees_[2] = F3Ddatasets.Fee(4,1,0);    //coscBuyFee
        // fees_[3] = F3Ddatasets.Fee(0,0,0);   //coscSellFee
    }

    // **
    //  * @dev used to make sure no one can interact with contract until it has
    //  * been activated.
    //  *
    // modifier isActivated() {
    //     require(activated_ == true, "its not ready yet.  check ?eta in discord");
    //     _;
    // }

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
    
    // ---------
    // Dont accept ETH;
    // ---------
    function () public payable { 
        revert();
    }

    function buyXaddr(address _pAddr, address _affCode, uint256 _eth, string _keyType)//sent
    // isActivated()
    // isHuman()
    onlyOwner()
    // isWithinLimits(msg.value)
    public
    // payable
    // returns(uint256)
    {
        // set up our tx event data and determine if player is new or not
        // F3Ddatasets.EventReturns memory _eventData_;
        // _eventData_ = determinePID(_eventData_);
        determinePID(_pAddr);

        // fetch player id
        uint256 _pID = pIDxAddr_[_pAddr];

        // manage affiliate residuals
        uint256 _affID;
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == address(0) || _affCode == _pAddr)
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
        buyCore(_pID, _affID, _eth, _keyType);
    }

    function registerNameXaddr(string   memory  _nameString, address _affCode, bool _all)//sent,user
    // isHuman()
    // onlyOwner()
    public
    payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXaddrFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);

        if(_isNewPlayer) plyNum_++;

        uint256 _pID = pIDxAddr_[_addr];

        // fire event
        emit F3Devents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }

    function ttlSply()
    public
    view
    returns(uint256, uint256, uint256, uint256)
    {
        return (cosdNum_, coscNum_, totalVolume_, totalVltCosd_);
    }
   
    function getBuyPrice()
    public
    view
    returns(uint256)
    {
        return price_;
    }
  
    function getPlayerInfoByAddress(address _addr)
    public
    view
    returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        // setup local rID
        // uint256 _rID = rID_;
        // address _addr = _addr_;

        // if (_addr == address(0))
        // {
        //     _addr == msg.sender;
        // }
        uint256 _pID = pIDxAddr_[_addr];

        return
        (
            _pID,
            plyr_[_pID].name,
            plyr_[_pID].laff,    
            plyr_[_pID].eth,
            plyr_[_pID].cosd,       
            plyr_[_pID].cosc,
            plyr_[_pID].hldVltCosd,
            plyr_[_pID].affCosd,
            plyr_[_pID].affCosc,
            plyr_[_pID].totalHldVltCosd,
            plyr_[_pID].totalAffCos,
            plyr_[_pID].totalWinCos
        );
    }

   
    function buyCore(uint256 _pID, uint256 _affID, uint256 _eth, string _keyType)
    private
    // returns(uint256)
    {
        uint256 _keys;
        // if eth left is greater than min eth allowed (sorry no pocket lint)
        if (_eth >= 0)
        {
            require(_eth >= getBuyPrice());
            // mint the new keys
            _keys = keysRec(_eth);
            // pay 2% out to community rewards
            uint256 _aff;
            uint256 _com;
            uint256 _holders;
            uint256 _self;

            // if (isCosd(_keyType) == true) {
            //     _aff        = _keys.mul(fees_[0].aff)/100;
            //     _com        = _keys.mul(fees_[0].com)/100;
            //     _holders    = _keys.mul(fees_[0].holders)/100;
            //     _self       = _keys.sub(_aff).sub(_com).sub(_holders);
            // }else{
            //     _aff        = _keys.mul(fees_[2].aff)/100;
            //     _com        = _keys.mul(fees_[2].com)/100;
            //     _holders    = _keys.mul(fees_[2].holders)/100;
            //     _self       = _keys.sub(_aff).sub(_com).sub(_holders);
            // }

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
            if(isCosd(_keyType) == true){
                
                _aff        = _keys * 5/100;
                _com        = _keys * 2/100;
                _holders    = _keys * 3/100;
                _self       = _keys.sub(_aff).sub(_com).sub(_holders);

                uint256 _hldCosd;
                for (uint256 i = 1; i <= plyNum_; i++) {
                    if(plyr_[i].cosd>0) _hldCosd = _hldCosd.add(plyr_[i].cosd);
                }

                //Player
                plyr_[_pID].cosd = plyr_[_pID].cosd.add(_self);
                plyr_[pIDCom_].cosd = plyr_[pIDCom_].cosd.add(_com);
                plyr_[_affID].affCosd = plyr_[_affID].affCosd.add(_aff);
                
                // plyr_[_affID].totalAffCos = plyr_[_affID].totalAffCos.add(_aff);

                for (uint256 j = 1; j <= plyNum_; j++) {
                    if(plyr_[j].cosd>0) {
                        // plyrRnds_[j][_rID].cosd = plyrRnds_[j][_rID].cosd.add(_holders.div(_otherHodles));
                        plyr_[j].hldVltCosd = plyr_[j].hldVltCosd.add(_holders.mul(plyr_[j].cosd).div(_hldCosd));
                        
                        // plyr_[j].totalHldVltCosd = plyr_[j].totalHldVltCosd.add(_holders.mul(plyr_[j].cosd).div(_hldCosd));
                        // totalVltCosd_ = totalVltCosd_.add(_holders.mul(plyr_[j].cosd).div(_hldCosd));
                        emit F3Devents.onRecHldVltCosd
                        (
                            plyr_[j].addr,
                            plyr_[j].name,
                            plyr_[j].hldVltCosd
                        );
                    }
                }
                //team
                // rndTmEth_[_rID][_team].cosd = _self.add(rndTmEth_[_rID][_team].cosd);
                cosdNum_ = cosdNum_.add(_keys);
                totalVolume_ = totalVolume_.add(_keys);
            }
            else{//cosc
                _aff        = _keys *4/100;
                _com        = _keys *1/100;
                // _holders    = _keys.mul(fees_[2].holders)/100;
                _self       = _keys.sub(_aff).sub(_com);
                //Player
                plyr_[_pID].cosc = plyr_[_pID].cosc.add(_self);
                plyr_[pIDCom_].cosc = plyr_[pIDCom_].cosc.add(_com);
                plyr_[_affID].affCosc = plyr_[_affID].affCosc.add(_aff);
                
                // plyr_[_affID].totalAffCos = plyr_[_affID].totalAffCos.add(_aff);
                // rndTmEth_[_rID][_team].cosc = _self.add(rndTmEth_[_rID][_team].cosc);
                coscNum_ = coscNum_.add(_keys);
                totalVolume_ = totalVolume_.add(_keys);
            }

            // keyNum_ = keyNum_.add(_keys);//update
        }

        // return _keys;
    }  

   
    function sellKeys(uint256 _pID, uint256 _keys, string _keyType)//send
    // isActivated()
    // isHuman()
    onlyOwner()
    // isWithinLimits(msg.value)
    public
    // payable
    returns(uint256)
    {
        // uint256 _pID = _pID_;
        // uint256 _keys = _keys_;
        require(_keys>0);
        uint256 _eth;

        // uint256 _aff;
        // uint256 _com;
        uint256 _holders;
        uint256 _self;
        // if (isCosd(_keyType) == true) {
        //         // _aff        = _keys.mul(fees_[1].aff)/100;
        //         // _com        = _keys.mul(fees_[1].com)/100;
        //         _holders    = _keys.mul(fees_[1].holders)/100;
        //         // _self       = _keys.sub(_aff).sub(_com);
        //         _self       = _self.sub(_holders);
        // }else{
        //         // _aff        = _keys.mul(fees_[3].aff)/100;
        //         // _com        = _keys.mul(fees_[3].com)/100;
        //         _holders    = _keys.mul(fees_[3].holders)/100;
        //         // _self       = _keys.sub(_aff).sub(_com);
        //         _self       = _self.sub(_holders);
        // }
        //split
       if(isCosd(_keyType) == true){
                require(plyr_[_pID].cosd >= _keys,"Do not have cosd!");
                
                // _aff        = _keys.mul(fees_[1].aff)/100;
                // _com        = _keys.mul(fees_[1].com)/100;
                _holders    = _keys * 20/100;
                // _self       = _keys.sub(_aff).sub(_com);
                _self       = _keys.sub(_holders);

                uint256 _hldCosd;
                for (uint256 i = 1; i <= plyNum_; i++) {
                    if(plyr_[i].cosd>0) _hldCosd = _hldCosd.add(plyr_[i].cosd);
                }

                plyr_[_pID].cosd = plyr_[_pID].cosd.sub(_keys);

                _eth = ethRec(_self);
                plyr_[_pID].eth = plyr_[_pID].eth.add(_eth);

                for (uint256 j = 1; j <= plyNum_; j++) {
                    if( plyr_[j].cosd>0) {                    
                        plyr_[j].hldVltCosd = plyr_[j].hldVltCosd.add(_holders.mul(plyr_[j].cosd).div(_hldCosd));
                        
                        // plyr_[j].totalHldVltCosd = plyr_[j].totalHldVltCosd.add(_holders.mul(plyr_[j].cosd).div(_hldCosd));
                        // totalVltCosd_ = totalVltCosd_.add(_holders.mul(plyr_[j].cosd).div(_hldCosd));
                        emit F3Devents.onRecHldVltCosd
                        (
                            plyr_[j].addr,
                            plyr_[j].name,
                            plyr_[j].hldVltCosd
                        );
                    }
                }
                cosdNum_ = cosdNum_.sub(_self);
                totalVolume_ = totalVolume_.add(_keys);
       }
       else{
            require(plyr_[_pID].cosc >= _keys,"Do not have cosc!");           

            plyr_[_pID].cosc = plyr_[_pID].cosc.sub(_keys);

            _eth = ethRec(_keys);
            plyr_[_pID].eth = plyr_[_pID].eth.add(_eth);
            
            coscNum_ = coscNum_.sub(_keys);
            totalVolume_ = totalVolume_.add(_keys);
       }

    //   keyNum_ = keyNum_.sub(_keys);//update
       // _eth = _keys.ethRec(getBuyPrice());

       return _eth;
    }

    function addCosToGame(uint256 _pID, uint256 _keys, string _keyType)//sent
    onlyOwner()
    public
    // returns(bool)
    {
            // uint256 _rID = rID_;
            // uint256 _now = now;

            uint256 _aff;
            uint256 _com;
            uint256 _holders;
            // uint256 _self;
            uint256 _affID = plyr_[_pID].laff;

            // update player
            if(isCosd(_keyType) == true){         //扣除9%

                require(plyr_[_pID].cosd >= _keys);

                _aff        = _keys *1/100;
                _com        = _keys *3/100;
                _holders    = _keys *5/100;
                // _self       = _keys.sub(_aff).sub(_com).sub(_holders);
                //Player
                plyr_[_pID].cosd = plyr_[_pID].cosd.sub(_keys);

                uint256 _hldCosd;
                for (uint256 i = 1; i <= plyNum_; i++) {
                    if(plyr_[i].cosd>0) _hldCosd = _hldCosd.add(plyr_[i].cosd);
                }

                //Player
                // plyr_[_pID].cosd = plyr_[_pID].cosd.add(_self);
                plyr_[pIDCom_].cosd = plyr_[pIDCom_].cosd.add(_com);
                plyr_[_affID].affCosd = plyr_[_affID].affCosd.add(_aff);
            
                // plyr_[_affID].totalAffCos = plyr_[_affID].totalAffCos.add(_aff);

                for (uint256 j = 1; j <= plyNum_; j++) {
                    if(plyr_[j].cosd>0) {
                        // plyrRnds_[j][_rID].cosd = plyrRnds_[j][_rID].cosd.add(_holders.div(_otherHodles));
                        plyr_[j].hldVltCosd = plyr_[j].hldVltCosd.add(_holders.mul(plyr_[j].cosd).div(_hldCosd));
                        
                        // plyr_[j].totalHldVltCosd = plyr_[j].totalHldVltCosd.add(_holders.mul(plyr_[j].cosd).div(_hldCosd));
                        // totalVltCosd_ = totalVltCosd_.add(_holders.mul(plyr_[j].cosd).div(_hldCosd));
                        emit F3Devents.onRecHldVltCosd
                        (
                            plyr_[j].addr,
                            plyr_[j].name,
                            plyr_[j].hldVltCosd
                        );
                    }
                }
            }
            else{//cosc
                require(plyr_[_pID].cosc >= _keys);
                //Player
                plyr_[_pID].cosc = plyr_[_pID].cosc.sub(_keys);
            }
        
            // return true;
    }

    function winCosFromGame(uint256 _pID, uint256 _keys, string _keyType)//sent
    onlyOwner()
    public
    // returns(bool)
    {
            // uint256 _rID = rID_;
            // uint256 _now = now;

            // update player
            if(isCosd(_keyType) == true){
                // require(plyr_[_pID].cosd >= _keys);
                //Player
                plyr_[_pID].cosd = plyr_[_pID].cosd.add(_keys);
            }
            else{//cosc
                // require(plyr_[_pID].cosc >= _keys);
                //Player
                plyr_[_pID].cosc = plyr_[_pID].cosc.add(_keys);
            }
            
            plyr_[_pID].totalWinCos = plyr_[_pID].totalWinCos.add(_keys);
        
            // return true;
    }    
   
    function iWantXKeys(uint256 _keys)
    public
    view
    returns(uint256)
    {
        return eth(_keys);
    }
    
    function howManyKeysCanBuy(uint256 _eth)
    public
    view
    returns(uint256)
    {
        return keys(_eth);
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
    function determinePID(address _pAddr)
    private
    {
        uint256 _pID = pIDxAddr_[_pAddr];
        // if player is new to this version of fomo3d
        if (_pID == 0)
        {
            // grab their player ID, name and last aff ID, from player names contract
            _pID = PlayerBook.getPlayerID(_pAddr);
            bytes32 _name = PlayerBook.getPlayerName(_pID);
            uint256 _laff = PlayerBook.getPlayerLAff(_pID);

            // set up player account
            pIDxAddr_[_pAddr] = _pID;
            plyr_[_pID].addr = _pAddr;

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
            // plyNum_++;
        }
        // return (_eventData_);
    }
    
    function withdrawETH(uint256 _pID)//send
    // isHuman()
    onlyOwner()
    public
    returns(bool)
    {
        if (plyr_[_pID].eth>0) {
            plyr_[_pID].eth = 0;
        }
        return true;
    }

    function withdrawHoldVault(uint256 _pID)//send
    // isHuman()
    onlyOwner()
    public
    returns(bool)
    {
        if (plyr_[_pID].hldVltCosd>0) {
            plyr_[_pID].cosd = plyr_[_pID].cosd.add(plyr_[_pID].hldVltCosd);
            
            plyr_[_pID].totalHldVltCosd = plyr_[_pID].totalHldVltCosd.add(plyr_[_pID].hldVltCosd);
            totalVltCosd_ = totalVltCosd_.add(plyr_[_pID].hldVltCosd);
                        
            plyr_[_pID].hldVltCosd = 0;
        }

        emit F3Devents.onWithdrawHoldVault
                    (
                        _pID,
                        plyr_[_pID].addr,
                        plyr_[_pID].name,
                        plyr_[_pID].cosd,
                        plyr_[_pID].hldVltCosd
                    );

        return true;
    }

    function withdrawAffVault(uint256 _pID, string _keyType)//send
    // isHuman()
    onlyOwner()
    public
    returns(bool)
    {

        if(isCosd(_keyType) == true){

            if (plyr_[_pID].affCosd>0) {
                plyr_[_pID].cosd = plyr_[_pID].cosd.add(plyr_[_pID].affCosd);
                plyr_[_pID].totalAffCos = plyr_[_pID].totalAffCos.add(plyr_[_pID].affCosd);
                plyr_[_pID].affCosd = 0;
            }
        }
        else{
            if (plyr_[_pID].affCosc>0) {
                plyr_[_pID].cosc = plyr_[_pID].cosc.add(plyr_[_pID].affCosc);
                plyr_[_pID].totalAffCos = plyr_[_pID].totalAffCos.add(plyr_[_pID].affCosc);
                plyr_[_pID].affCosc = 0;
            }
        }

        emit F3Devents.onWithdrawAffVault
        (
                        _pID,
                        plyr_[_pID].addr,
                        plyr_[_pID].name,
                        plyr_[_pID].cosd,
                        plyr_[_pID].cosc,
                        plyr_[_pID].affCosd,
                        plyr_[_pID].affCosc
        );

        return true;
    }

    function transferToAnotherAddr(address _from, address _to, uint256 _keys, string _keyType) //sent
    // isHuman()
    onlyOwner()
    public
    // returns(bool)
    {
        // uint256 _rID = rID_;
        // uint256 _holders;
        // uint256 _self;
        // uint256 i;

        // determinePID();
        // fetch player id
        uint256 _pID = pIDxAddr_[_from];
        uint256 _tID = pIDxAddr_[_to];

        require(_tID > 0);
    
        if (isCosd(_keyType) == true) {

                require(plyr_[_pID].cosd >= _keys);

                // uint256 _hldCosd;
                // for ( i = 1; i <= plyNum_; i++) {
                //     if(plyr_[i].cosd>0) _hldCosd = _hldCosd.add(plyr_[i].cosd);
                // }

                // _holders = _keys * 20/100;
                // // _aff =     plyrRnds_[_pID][_rID].wonCosd * 1/100;
                // _self = _keys.sub(_holders);

                plyr_[_tID].cosd = plyr_[_tID].cosd.add(_keys);
                plyr_[_pID].cosd = plyr_[_pID].cosd.sub(_keys);

                // for ( i = 1; i <= plyNum_; i++) {
                //     if(plyr_[i].cosd>0) plyr_[i].hldVltCosd = plyr_[i].hldVltCosd.add(_holders.mul(plyr_[i].cosd).div(_hldCosd));
                // }
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

        // return true;
    }
    
    function isCosd(string _keyType)
    public
    pure
    returns(bool)
    {
        if( bytes(_keyType).length == 8 )
        {
            return true;
        }
        else 
        {
            return false;
        }
    }
    
    // function setResult(string _keyType) //send
    // public
    // // pure
    // returns(string)
    // {
    //     result_ = bytes(_keyType).length;
        
    //     return (_keyType);
    // }
    
    // function getResult(string _keyType)
    // public
    // pure
    // returns(uint256)
    // {
    //     // return bytes(_keyType).length;
    //     if( bytes(_keyType).length == 8 )
    //     {
    //         return 100;
    //     }
    //     else 
    //     {
    //         return 50;
    //     }
    // }
    
    function keysRec(uint256 _eth)
    internal
    returns (uint256)
    {
        // require(_price >= 10**16);
        
        uint256 _rstAmount = 0;
        uint256 _price = price_;
        // uint256 _keyNum = cosdNum_.add(coscNum_);
        // require(_eth >= msg.value);

        while(_eth >= _price){
            _eth = _eth - _price;
            _price = _price + 5 *10**11;
            
            if(_price >= 2 *10**17){ 
                _price = 2 *10**17;
                // priceCntThreshould_ = _keyNum.add(_rstAmount);
            }
            
            _rstAmount++;
        }
        
        price_ = _price;

        return _rstAmount;
    }

    function ethRec(uint256 _keys)
    internal
    returns (uint256)
    {
        // require(_price >= 10**16);
        
        uint256 _eth = 0;
        uint256 _price = price_;
        uint256 _keyNum = cosdNum_.add(coscNum_);
        // require(_eth >= msg.value);

        for(uint256 i=0;i < _keys;i++){
            if(_price < 10**16) _price = 10**16;
            
            _eth = _eth + _price;
            _price = _price - 5 *10**11;
            
            if(_price < 10**16) _price = 10**16;
            if(_keyNum - i >= priceCntThreshould_) _price = 2 *10**17; 
        }
        
        price_ = _price;

        return _eth;
    }

    function keys(uint256 _eth)
    internal
    view
    returns(uint256)
    {
         // require(_price >= 10**16);
        
        uint256 _rstAmount = 0;
        uint256 _price = price_;
        // uint256 _keyNum = cosdNum_.add(coscNum_);
        // require(_eth >= msg.value);

        while(_eth >= _price){
            _eth = _eth - _price;
            _price = _price + 5 *10**11;
            
            if(_price >= 2 *10**17){ 
                _price = 2 *10**17;
                // priceCntThreshould_ = _keyNum.add(_rstAmount);
            }
            
            _rstAmount++;
        }
        
        // price_ = _price;

        return _rstAmount;
    }

    function eth(uint256 _keys)
    internal
    view
    returns(uint256)
    {
        // require(_price >= 10**16);
        
        uint256 _eth = 0;
        uint256 _price = price_;
        uint256 _keyNum = cosdNum_.add(coscNum_);
        // require(_eth >= msg.value);

        for(uint256 i=0;i < _keys;i++){
            if(_price < 10**16) _price = 10**16;
            
            _eth = _eth + _price;
            _price = _price - 5 *10**11;
            
            if(_price < 10**16) _price = 10**16;
            if(_keyNum - i >= priceCntThreshould_) _price = 2 *10**17; 
        }
        
        // price_ = _price;

        return _eth;
    }
    
    //==============================================================================
    //    (~ _  _    _._|_    .
    //    _)(/_(_|_|| | | \/  .
    //====================/=========================================================
    // ** upon contract deploy, it will be deactivated.  this is a one time
    //  * use function that will activate the contract.  we do this so devs
    //  * have time to set things up on the web end                            **
    // bool public activated_ = false;
    // function activate()
    // public 
    // onlyOwner {
    //     // make sure that its been linked.
    //     //        require(address(otherF3D_) != address(0), "must link to other FoMo3D first");

    //     // can only be ran once
    //     require(activated_ == false, "fomo3d already activated");

    //     // activate the contract
    //     activated_ = true;

    //     // lets start first round
    //     // rID_ = 1;
    //     // round_[1].strt = now;
    //     // round_[1].end  = now.add(rndInit_);
    // }
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
        uint256 laff;   // last affiliate id used
        uint256 eth;
        uint256 cosd;    // winnings vault
        uint256 cosc;    // winnings vault
        // uint256 lrnd;   // last round played
        // uint256 rounds; //超过xxxcosd的轮数累计
        // uint256 redtProp; //买道具赠送的累计亏损减少率
        // uint256 redt1;
        // uint256 redt3;
        uint256 hldVltCosd;
        uint256 affCosd;
        uint256 affCosc;
        uint256 totalHldVltCosd;
        uint256 totalAffCos;
        uint256 totalWinCos;
    }
    // struct PlayerRounds {
    //     uint256 cosd;   // keys
    //     uint256 cosc;   // keys
    //     bool hadProp;
    //     uint256 propID;
    //     uint256 redtPRProp; //lossReductionRate，玩家当前回合道具总亏损减少率
    //     uint256 incrPRProp; //Income increase rate收入增加率
    //     uint256 team;
    //     // bool first;
    //     uint256 firstCosd;//第一阶段投入的COS资金，可减少20% 亏损率
    //     uint256 firstCosc;//第一阶段投入的COS资金，可减少20% 亏损率
    //     uint256 redtPRFirst;
    //     uint256 wonCosd;
    //     uint256 wonCosc;
    //     uint256 wonCosdRcd;
    //     uint256 wonCoscRcd;
    // }
    // struct Round {
    //     uint256 plyr;   // pID of player in lead
    //     uint256 team;   // tID of team in lead
    //     uint256 end;    // time ends/ended
    //     bool ended;     // has round end function been ran
    //     uint256 strt;   // time round started
    //     uint256 cosd;   // keys
    //     uint256 cosc;   // keys
    //     uint256 winTeam;
    // }     
    // struct Team {
    //     uint256 teamID;        
    //     uint256 winRate;    // 胜率
    //     uint256 eth;
    //     uint256 cosd;
    //     uint256 cosc;
    // }
    // struct Prop {           //道具
    //     uint256 propID;         
    //     uint256 price;
    //     uint256 oID;
    // }
    // struct Leader {           //道具       
    //     uint256 price;
    //     uint256 oID;
    // }
    // struct Fee {
    //     uint256 aff;          // % of buy in thats paid to referrer  of current round推荐人分配比例
    //     uint256 com;    // % of buy in thats paid for comnunity
    //     uint256 holders; //key holders
    // }
}

library F3DKeysCalcLong {
    using SafeMath for *;

    function random() internal pure returns (uint256) {
       uint ranNum = uint(keccak256(msg.data)) % 100;
       return ranNum;
   }
}