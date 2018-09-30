pragma solidity ^0.4.24;



interface DiviesInterface {
    function deposit() external payable;
}
interface otherFoMo3D {
    function potSwap() external payable;
}
interface JIincForwarderInterface {
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
interface F3DexternalSettingsInterface {
    function getFastGap() external returns(uint256);
    function getLongGap() external returns(uint256);
    function getFastExtra() external returns(uint256);
    function getLongExtra() external returns(uint256);
}
interface HourglassInterface {
    function() payable external;
    function buy(address _playerAddress) payable external returns(uint256);
    function sell(uint256 _amountOfTokens) external;
    function reinvest() external;
    function withdraw() external;
    function exit() external;
    function dividendsOf(address _playerAddress) external view returns(uint256);
    function balanceOf(address _playerAddress) external view returns(uint256);
    function transfer(address _toAddress, uint256 _amountOfTokens) external returns(bool);
    function stakingRequirement() external view returns(uint256);
}

library SafeMath {

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
    

    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }

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
    

    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    

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
library UintCompressor {
    using SafeMath for *;
    
    function insert(uint256 _var, uint256 _include, uint256 _start, uint256 _end)
        internal
        pure
        returns(uint256)
    {
        
        require(_end < 77 && _start < 77, "start/end must be less than 77");
        require(_end >= _start, "end must be >= start");
        
       
        _end = exponent(_end).mul(10);
        _start = exponent(_start);
        
        
        require(_include < (_end / _start));
        

        if (_include > 0)
            _include = _include.mul(_start);
        
        return((_var.sub((_var / _start).mul(_start))).add(_include).add((_var / _end).mul(_end)));
    }
    
    function extract(uint256 _input, uint256 _start, uint256 _end)
	    internal
	    pure
	    returns(uint256)
    {
        
        require(_end < 77 && _start < 77, "start/end must be less than 77");
        require(_end >= _start, "end must be >= start");
        
        
        _end = exponent(_end).mul(10);
        _start = exponent(_start);
        
        
        return((((_input / _start).mul(_start)).sub((_input / _end).mul(_end))) / _start);
    }
    
    function exponent(uint256 _position)
        private
        pure
        returns(uint256)
    {
        return((10).pwr(_position));
    }
}
library NameFilter {

    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        
        
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
        
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
        
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }
        
        
        bool _hasNonNumber;
        
        
        for (uint256 i = 0; i < _length; i++)
        {
            
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                
                _temp[i] = byte(uint(_temp[i]) + 32);
                
                
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                    
                    _temp[i] == 0x20 || 
                    
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                    
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");
                
                
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

library F3DKeysCalcLong {
    using SafeMath for *;

    function keysRec(uint256 _curEth, uint256 _newEth)
        internal
        pure
        returns (uint256)
    {
        return(keys((_curEth).add(_newEth)).sub(keys(_curEth)));
    }
    

    function ethRec(uint256 _curKeys, uint256 _sellKeys)
        internal
        pure
        returns (uint256)
    {
        return((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
    }


    function keys(uint256 _eth) 
        internal
        pure
        returns(uint256)
    {
        return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000);
    }
    

    function eth(uint256 _keys) 
        internal
        pure
        returns(uint256)  
    {
        return ((78125000).mul(_keys.sq()).add(((149999843750000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
    }
}
library F3Ddatasets {

    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr;         
        bytes32 winnerName;         
        uint256 amountWon;          
        uint256 newPot;             
        uint256 P3DAmount;          
        uint256 genAmount;          
        uint256 potAmount;          
    }
    struct Player {
        address addr;   
        bytes32 name;   
        uint256 win;    
        uint256 gen;    
        uint256 aff;    
        uint256 lrnd;   
        uint256 laff;   
    }
    struct PlayerRounds {
        uint256 eth;    
        uint256 keys;   
        uint256 mask;   
        uint256 ico;    
    }
    struct Round {
        uint256 plyr;   
        uint256 team;   
        uint256 end;    
        bool ended;     
        uint256 strt;   
        uint256 keys;   
        uint256 eth;    
        uint256 pot;    
        uint256 mask;   
        uint256 ico;    
        uint256 icoGen; 
        uint256 icoAvg; 
    }
    struct TeamFee {
        uint256 gen;    
        uint256 p3d;    
    }
    struct PotSplit {
        uint256 gen;    
        uint256 p3d;    
    }
}


contract F3Devents {
    
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
        uint256 newPot,
        uint256 P3DAmount,
        uint256 genAmount
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
        uint256 newPot,
        uint256 P3DAmount,
        uint256 genAmount
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
        uint256 newPot,
        uint256 P3DAmount,
        uint256 genAmount
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
    
    
    event onPotSwapDeposit
    (
        uint256 roundID,
        uint256 amountAddedToPot
    );
}

contract modularLong is F3Devents {}

contract FoMo3Dlong is modularLong {
    using SafeMath for *;
    using NameFilter for string;
    using F3DKeysCalcLong for uint256;
    
    otherFoMo3D private otherF3D_;
    DiviesInterface constant private Divies = DiviesInterface(0x5d56e81fD64eDfb2bBDa0ebC770115db4497D2d5);
    JIincForwarderInterface constant private Jekyll_Island_Inc = JIincForwarderInterface(0xCffc7046029D5EF1B4B07662f5f1ED6DaD6cb413);
    PlayerBookInterface constant private PlayerBook = PlayerBookInterface(0xdca110c5D88e5da4664B8976748F217B6E824B0C);
    F3DexternalSettingsInterface constant private extSettings = F3DexternalSettingsInterface(0x22e3F45B2A519CCFEC4C856fbb87985890f4dde0);
    
    string constant public name = "FoMo3D Long Official";
    string constant public symbol = "F3D";
    uint256 private rndExtra_ = extSettings.getLongExtra();     
    uint256 private rndGap_ = extSettings.getLongGap();         
    uint256 constant private rndInit_ = 1 hours;                
    uint256 constant private rndInc_ = 30 seconds;              
    uint256 constant private rndMax_ = 24 hours;                
    
    uint256 public airDropPot_;             
    uint256 public airDropTracker_ = 0;     
    uint256 public rID_;    

    mapping (address => uint256) public pIDxAddr_;          
    mapping (bytes32 => uint256) public pIDxName_;          
    mapping (uint256 => F3Ddatasets.Player) public plyr_;   
    mapping (uint256 => mapping (uint256 => F3Ddatasets.PlayerRounds)) public plyrRnds_;    
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_; 

    mapping (uint256 => F3Ddatasets.Round) public round_;   
    mapping (uint256 => mapping(uint256 => uint256)) public rndTmEth_;      

    mapping (uint256 => F3Ddatasets.TeamFee) public fees_;          
    mapping (uint256 => F3Ddatasets.PotSplit) public potSplit_;     
    
    constructor()
        public
    {

            
        fees_[0] = F3Ddatasets.TeamFee(30,6);   
        fees_[1] = F3Ddatasets.TeamFee(43,0);   
        fees_[2] = F3Ddatasets.TeamFee(56,10);  
        fees_[3] = F3Ddatasets.TeamFee(43,8);   
        
        
        
        potSplit_[0] = F3Ddatasets.PotSplit(15,10);  
        potSplit_[1] = F3Ddatasets.PotSplit(25,0);   
        potSplit_[2] = F3Ddatasets.PotSplit(20,20);  
        potSplit_[3] = F3Ddatasets.PotSplit(30,10);  
    }

   /**
    * MODIFIERS
    * */
    

    modifier isActivated() {
        require(activated_ == true, "its not ready yet.  check ?eta in discord"); 
        _;
    }
    

    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }


    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;    
    }
    
   /**
    * PUBLIC FUNCTIONS
    * */

    function()
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
            
        
        uint256 _pID = pIDxAddr_[msg.sender];
        
        
        buyCore(_pID, plyr_[_pID].laff, 2, _eventData_);
    }

    function buyXid(uint256 _affCode, uint256 _team)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        
        
        uint256 _pID = pIDxAddr_[msg.sender];
        
        
        
        if (_affCode == 0 || _affCode == _pID)
        {
            
            _affCode = plyr_[_pID].laff;
            
        
        } else if (_affCode != plyr_[_pID].laff) {
            
            plyr_[_pID].laff = _affCode;
        }
        
        
        _team = verifyTeam(_team);
        
        
        buyCore(_pID, _affCode, _team, _eventData_);
    }
    
    function buyXaddr(address _affCode, uint256 _team)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        
        
        uint256 _pID = pIDxAddr_[msg.sender];
        
        
        uint256 _affID;
        
        if (_affCode == address(0) || _affCode == msg.sender)
        {
            
            _affID = plyr_[_pID].laff;
        
        
        } else {
            
            _affID = pIDxAddr_[_affCode];
            
            
            if (_affID != plyr_[_pID].laff)
            {
                
                plyr_[_pID].laff = _affID;
            }
        }
        
        
        _team = verifyTeam(_team);
        
        
        buyCore(_pID, _affID, _team, _eventData_);
    }
    
       function buyXname(bytes32 _affCode, uint256 _team)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        
        
        uint256 _pID = pIDxAddr_[msg.sender];
        
        
        uint256 _affID;
        
        if (_affCode == &#39;&#39; || _affCode == plyr_[_pID].name)
        {
            
            _affID = plyr_[_pID].laff;
        
        
        } else {
            
            _affID = pIDxName_[_affCode];
            
            
            if (_affID != plyr_[_pID].laff)
            {
                
                plyr_[_pID].laff = _affID;
            }
        }
        
        
        _team = verifyTeam(_team);
        
        
        buyCore(_pID, _affID, _team, _eventData_);
    }
    
    
    
    
       /**
    * GETTERS
    * */
    

    function getBuyPrice()
        public 
        view 
        returns(uint256)
    {  
        
        uint256 _rID = rID_;
        
        
        uint256 _now = now;
        
        
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].keys.add(1000000000000000000)).ethRec(1000000000000000000) );
        else 
            return ( 75000000000000 ); 
    }
    

    function getTimeLeft()
        public
        view
        returns(uint256)
    {
        
        uint256 _rID = rID_;
        
        
        uint256 _now = now;
        
        if (_now < round_[_rID].end)
            if (_now > round_[_rID].strt + rndGap_)
                return( (round_[_rID].end).sub(_now) );
            else
                return( (round_[_rID].strt + rndGap_).sub(_now) );
        else
            return(0);
    }
    

    function getPlayerVaults(uint256 _pID)
        public
        view
        returns(uint256 ,uint256, uint256)
    {
        
        uint256 _rID = rID_;
        
        
        if (now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
            
            if (round_[_rID].plyr == _pID)
            {
                return
                (
                    (plyr_[_pID].win).add( ((round_[_rID].pot).mul(48)) / 100 ),
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)   ),
                    plyr_[_pID].aff
                );
            
            } else {
                return
                (
                    plyr_[_pID].win,
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)  ),
                    plyr_[_pID].aff
                );
            }
            
        
        } else {
            return
            (
                plyr_[_pID].win,
                (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),
                plyr_[_pID].aff
            );
        }
    }
    

    function getPlayerVaultsHelper(uint256 _pID, uint256 _rID)
        private
        view
        returns(uint256)
    {
        return(  ((((round_[_rID].mask).add(((((round_[_rID].pot).mul(potSplit_[round_[_rID].team].gen)) / 100).mul(1000000000000000000)) / (round_[_rID].keys))).mul(plyrRnds_[_pID][_rID].keys)) / 1000000000000000000)  );
    }
    

    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, bytes32, uint256, uint256, uint256, uint256, uint256)
    {
        
        uint256 _rID = rID_;
        
        return
        (
            round_[_rID].ico,               
            _rID,                           
            round_[_rID].keys,              
            round_[_rID].end,               
            round_[_rID].strt,              
            round_[_rID].pot,               
            (round_[_rID].team + (round_[_rID].plyr * 10)),     
            plyr_[round_[_rID].plyr].addr,  
            plyr_[round_[_rID].plyr].name,  
            rndTmEth_[_rID][0],             
            rndTmEth_[_rID][1],             
            rndTmEth_[_rID][2],             
            rndTmEth_[_rID][3],             
            airDropTracker_ + (airDropPot_ * 1000)              
        );
    }

    function getPlayerInfoByAddress(address _addr)
        public 
        view 
        returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256)
    {
        
        uint256 _rID = rID_;
        
        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];
        
        return
        (
            _pID,                               
            plyr_[_pID].name,                   
            plyrRnds_[_pID][_rID].keys,         
            plyr_[_pID].win,                    
            (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),       
            plyr_[_pID].aff,                    
            plyrRnds_[_pID][_rID].eth           
        );
    }
    
    
       /**
    * CORE LOGIC
    * */
    

    function buyCore(uint256 _pID, uint256 _affID, uint256 _team, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
        
        uint256 _rID = rID_;
        
        
        uint256 _now = now;
        
        
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) 
        {
            
            core(_rID, _pID, msg.value, _affID, _team, _eventData_);
        
        
        } else {
            
            if (_now > round_[_rID].end && round_[_rID].ended == false) 
            {
                
			    round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);
                
                
                _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
                _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;
                
                
                emit F3Devents.onBuyAndDistribute
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
            
            
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }
    

    function reLoadCore(uint256 _pID, uint256 _affID, uint256 _team, uint256 _eth, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
        
        uint256 _rID = rID_;
        
        
        uint256 _now = now;
        
        
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) 
        {
            
            
            
            plyr_[_pID].gen = withdrawEarnings(_pID).sub(_eth);
            
            
            core(_rID, _pID, _eth, _affID, _team, _eventData_);
        
        
        } else if (_now > round_[_rID].end && round_[_rID].ended == false) {
            
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);
                
            
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;
                
            
            emit F3Devents.onReLoadAndDistribute
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
    

    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
        
        if (plyrRnds_[_pID][_rID].keys == 0)
            _eventData_ = managePlayer(_pID, _eventData_);
        
        
        if (round_[_rID].eth < 100000000000000000000 && plyrRnds_[_pID][_rID].eth.add(_eth) > 1000000000000000000)
        {
            uint256 _availableLimit = (1000000000000000000).sub(plyrRnds_[_pID][_rID].eth);
            uint256 _refund = _eth.sub(_availableLimit);
            plyr_[_pID].gen = plyr_[_pID].gen.add(_refund);
            _eth = _availableLimit;
        }
        
        
        if (_eth > 1000000000) 
        {
            
            
            uint256 _keys = (round_[_rID].eth).keysRec(_eth);
            
            
            if (_keys >= 1000000000000000000)
            {
            updateTimer(_keys, _rID);

            
            if (round_[_rID].plyr != _pID)
                round_[_rID].plyr = _pID;  
            if (round_[_rID].team != _team)
                round_[_rID].team = _team; 
            
            
            _eventData_.compressedData = _eventData_.compressedData + 100;
        }
            
            
            if (_eth >= 100000000000000000)
            {
            airDropTracker_++;
            if (airdrop() == true)
            {
                
                uint256 _prize;
                if (_eth >= 10000000000000000000)
                {
                    
                    _prize = ((airDropPot_).mul(75)) / 100;
                    plyr_[_pID].win = (plyr_[_pID].win).add(_prize);
                    
                    
                    airDropPot_ = (airDropPot_).sub(_prize);
                    
                    
                    _eventData_.compressedData += 300000000000000000000000000000000;
                } else if (_eth >= 1000000000000000000 && _eth < 10000000000000000000) {
                    
                    _prize = ((airDropPot_).mul(50)) / 100;
                    plyr_[_pID].win = (plyr_[_pID].win).add(_prize);
                    
                    
                    airDropPot_ = (airDropPot_).sub(_prize);
                    
                    
                    _eventData_.compressedData += 200000000000000000000000000000000;
                } else if (_eth >= 100000000000000000 && _eth < 1000000000000000000) {
                    
                    _prize = ((airDropPot_).mul(25)) / 100;
                    plyr_[_pID].win = (plyr_[_pID].win).add(_prize);
                    
                    
                    airDropPot_ = (airDropPot_).sub(_prize);
                    
                    
                    _eventData_.compressedData += 300000000000000000000000000000000;
                }
                
                _eventData_.compressedData += 10000000000000000000000000000000;
                
                _eventData_.compressedData += _prize * 1000000000000000000000000000000000;
                
                
                airDropTracker_ = 0;
            }
        }
    
            
            _eventData_.compressedData = _eventData_.compressedData + (airDropTracker_ * 1000);
            
            
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);
            
            
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = _eth.add(round_[_rID].eth);
            rndTmEth_[_rID][_team] = _eth.add(rndTmEth_[_rID][_team]);
    
            
            _eventData_ = distributeExternal(_rID, _pID, _eth, _affID, _team, _eventData_);
            _eventData_ = distributeInternal(_rID, _pID, _eth, _team, _keys, _eventData_);
            
            
		    endTx(_pID, _team, _eth, _keys, _eventData_);
        }
    }
    
    
   /**
    * CALCULATORS
    * */
    
  
    function calcUnMaskedEarnings(uint256 _pID, uint256 _rIDlast)
        private
        view
        returns(uint256)
    {
        return(  (((round_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1000000000000000000)).sub(plyrRnds_[_pID][_rIDlast].mask)  );
    }
    

    function calcKeysReceived(uint256 _rID, uint256 _eth)
        public
        view
        returns(uint256)
    {
        
        uint256 _now = now;
        
        
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].eth).keysRec(_eth) );
        else 
            return ( (_eth).keys() );
    }
    

    function iWantXKeys(uint256 _keys)
        public
        view
        returns(uint256)
    {
        
        uint256 _rID = rID_;
        
        
        uint256 _now = now;
        
        
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].keys.add(_keys)).ethRec(_keys) );
        else 
            return ( (_keys).eth() );
    }
    
    
       /**
    * TOOLS
    * */
    

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
    

    function receivePlayerNameList(uint256 _pID, bytes32 _name)
        external
    {
        require (msg.sender == address(PlayerBook), "your not playerNames contract... hmmm..");
        if(plyrNames_[_pID][_name] == false)
            plyrNames_[_pID][_name] = true;
    }   
        

    function determinePID(F3Ddatasets.EventReturns memory _eventData_)
        private
        returns (F3Ddatasets.EventReturns)
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        
        if (_pID == 0)
        {
            
            _pID = PlayerBook.getPlayerID(msg.sender);
            bytes32 _name = PlayerBook.getPlayerName(_pID);
            uint256 _laff = PlayerBook.getPlayerLAff(_pID);
            
            
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
            
            
            _eventData_.compressedData = _eventData_.compressedData + 1;
        } 
        return (_eventData_);
    }
    

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
    

    function managePlayer(uint256 _pID, F3Ddatasets.EventReturns memory _eventData_)
        private
        returns (F3Ddatasets.EventReturns)
    {
        
        
        if (plyr_[_pID].lrnd != 0)
            updateGenVault(_pID, plyr_[_pID].lrnd);
            
        
        plyr_[_pID].lrnd = rID_;
            
        
        _eventData_.compressedData = _eventData_.compressedData + 10;
        
        return(_eventData_);
    }
    

    function endRound(F3Ddatasets.EventReturns memory _eventData_)
        private
        returns (F3Ddatasets.EventReturns)
    {
        
        uint256 _rID = rID_;
        
        
        uint256 _winPID = round_[_rID].plyr;
        uint256 _winTID = round_[_rID].team;
        
        
        uint256 _pot = round_[_rID].pot;
        
        
        
        uint256 _win = (_pot.mul(48)) / 100;
        uint256 _com = (_pot / 50);
        uint256 _gen = (_pot.mul(potSplit_[_winTID].gen)) / 100;
        uint256 _p3d = (_pot.mul(potSplit_[_winTID].p3d)) / 100;
        uint256 _res = (((_pot.sub(_win)).sub(_com)).sub(_gen)).sub(_p3d);
        
        
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        uint256 _dust = _gen.sub((_ppt.mul(round_[_rID].keys)) / 1000000000000000000);
        if (_dust > 0)
        {
            _gen = _gen.sub(_dust);
            _res = _res.add(_dust);
        }
        
        
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);
        
        
        if (!address(Jekyll_Island_Inc).call.value(_com)(bytes4(keccak256("deposit()"))))
        {
            
            
            
            
            
            
            _p3d = _p3d.add(_com);
            _com = 0;
        }
        
        
        round_[_rID].mask = _ppt.add(round_[_rID].mask);
        
        
        if (_p3d > 0)
            Divies.deposit.value(_p3d)();
            
        
        _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * 100000000000000000000000000) + (_winTID * 100000000000000000);
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.winnerName = plyr_[_winPID].name;
        _eventData_.amountWon = _win;
        _eventData_.genAmount = _gen;
        _eventData_.P3DAmount = _p3d;
        _eventData_.newPot = _res;
        
        
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_).add(rndGap_);
        round_[_rID].pot = _res;
        
        return(_eventData_);
    }
    

    function updateGenVault(uint256 _pID, uint256 _rIDlast)
        private 
    {
        uint256 _earnings = calcUnMaskedEarnings(_pID, _rIDlast);
        if (_earnings > 0)
        {
            
            plyr_[_pID].gen = _earnings.add(plyr_[_pID].gen);
            
            plyrRnds_[_pID][_rIDlast].mask = _earnings.add(plyrRnds_[_pID][_rIDlast].mask);
        }
    }
    

    function updateTimer(uint256 _keys, uint256 _rID)
        private
    {
        
        uint256 _now = now;
        
        
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

    function distributeExternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, F3Ddatasets.EventReturns memory _eventData_)
        private
        returns(F3Ddatasets.EventReturns)
    {
        
        uint256 _com = _eth / 50;
        uint256 _p3d;
        if (!address(Jekyll_Island_Inc).call.value(_com)(bytes4(keccak256("deposit()"))))
        {
            
            
            
            
            
            
            _p3d = _com;
            _com = 0;
        }
        
        
        uint256 _long = _eth / 100;
        otherF3D_.potSwap.value(_long)();
        
        
        uint256 _aff = _eth / 10;
        
        
        
        if (_affID != _pID && plyr_[_affID].name != &#39;&#39;) {
            plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
            emit F3Devents.onAffiliatePayout(_affID, plyr_[_affID].addr, plyr_[_affID].name, _rID, _pID, _aff, now);
        } else {
            _p3d = _aff;
        }
        
        
        _p3d = _p3d.add((_eth.mul(fees_[_team].p3d)) / (100));
        if (_p3d > 0)
        {
            
            Divies.deposit.value(_p3d)();
            
            
            _eventData_.P3DAmount = _p3d.add(_eventData_.P3DAmount);
        }
        
        return(_eventData_);
    }
    
    function potSwap()
        external
        payable
    {
        
        uint256 _rID = rID_ + 1;
        
        round_[_rID].pot = round_[_rID].pot.add(msg.value);
        emit F3Devents.onPotSwapDeposit(_rID, msg.value);
    }
    

    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _team, uint256 _keys, F3Ddatasets.EventReturns memory _eventData_)
        private
        returns(F3Ddatasets.EventReturns)
    {
        
        uint256 _gen = (_eth.mul(fees_[_team].gen)) / 100;
        
        
        uint256 _air = (_eth / 100);
        airDropPot_ = airDropPot_.add(_air);
        
        
        _eth = _eth.sub(((_eth.mul(14)) / 100).add((_eth.mul(fees_[_team].p3d)) / 100));
        
        
        uint256 _pot = _eth.sub(_gen);
        
        
        
        uint256 _dust = updateMasks(_rID, _pID, _gen, _keys);
        if (_dust > 0)
            _gen = _gen.sub(_dust);
        
        
        round_[_rID].pot = _pot.add(_dust).add(round_[_rID].pot);
        
        
        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _pot;
        
        return(_eventData_);
    }


    function updateMasks(uint256 _rID, uint256 _pID, uint256 _gen, uint256 _keys)
        private
        returns(uint256)
    {
   
        
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        round_[_rID].mask = _ppt.add(round_[_rID].mask);
            
        
        
        uint256 _pearn = (_ppt.mul(_keys)) / (1000000000000000000);
        plyrRnds_[_pID][_rID].mask = (((round_[_rID].mask.mul(_keys)) / (1000000000000000000)).sub(_pearn)).add(plyrRnds_[_pID][_rID].mask);
        
        
        return(_gen.sub((_ppt.mul(round_[_rID].keys)) / (1000000000000000000)));
    }
    

    function withdrawEarnings(uint256 _pID)
        private
        returns(uint256)
    {
        
        updateGenVault(_pID, plyr_[_pID].lrnd);
        
        
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen).add(plyr_[_pID].aff);
        if (_earnings > 0)
        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
            plyr_[_pID].aff = 0;
        }

        return(_earnings);
    }
    

    function endTx(uint256 _pID, uint256 _team, uint256 _eth, uint256 _keys, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
        _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000) + (_team * 100000000000000000000000000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + _pID + (rID_ * 10000000000000000000000000000000000000000000000000000);
        
        emit F3Devents.onEndTx
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
    
    
   /**
    * SECURITY
    * */
    bool public activated_ = false;
    function activate()
        public
    {
        
        require(
            msg.sender == 0x0f4029B6Ae4Ad3f6571FaE10236c66A98aBa08eF
        );


        require(activated_ == false, "fomo3d already activated");
        
        
        activated_ = true;
        
        
		rID_ = 1;
        round_[1].strt = now + rndExtra_ - rndGap_;
        round_[1].end = now + rndInit_ + rndExtra_;
    }

    
}