pragma solidity ^0.4.24;

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
library FMDDCalcLong {
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

contract Damo{
    using SafeMath for uint256;
    using NameFilter for string;
    using FMDDCalcLong for uint256; 
	uint256 iCommunityPot;
    struct Round{
        uint256 iKeyNum;
        uint256 iVault;
        uint256 iMask;
        address plyr;
		uint256 iGameStartTime;
		uint256 iGameEndTime;
		uint256 iSharePot;
		uint256 iSumPayable;
        bool bIsGameEnded; 
    }
	struct PlyRound{
        uint256 iKeyNum;
        uint256 iMask;	
	}
	
    struct Player{
        uint256 gen;
        uint256 affGen;
        uint256 iLastRoundId;
        bytes32 name;
        address aff;
        mapping (uint256=>PlyRound) roundMap;
    }
    event evtBuyKey( uint256 iRoundId,address buyerAddress,bytes32 buyerName,uint256 iSpeedEth,uint256 iBuyNum );
    event evtRegisterName( address addr,bytes32 name );
    event evtAirDrop( address addr,bytes32 name,uint256 _airDropAmt );
    event evtFirDrop( address addr,bytes32 name,uint256 _airDropAmt );
    event evtGameRoundStart( uint256 iRoundId, uint256 iStartTime,uint256 iEndTime,uint256 iSharePot );
    //event evtGameRoundEnd( uint256 iRoundId,   address iWinner, uint256 win );
    //event evtWithDraw( address addr,bytes32 name,uint256 WithDrawAmt );
    
    string constant public name = "FoMo3D Long Official";
    string constant public symbol = "F3D";
    uint256 constant public decimal = 1000000000000000000;
    uint256 public registrationFee_ = 10 finney;
	bool iActivated = false;
    uint256 iTimeInterval;
    uint256 iAddTime;
	uint256 addTracker_;
    uint256 public airDropTracker_ = 0;     // incremented each time a "qualified" tx occurs.  used to determine winning air drop
	uint256 public airDropPot_ = 0;
	// fake gas 
    uint256 public airFropTracker_ = 0; 
	uint256 public airFropPot_ = 0;


    mapping (address => Player) plyMap; 
    mapping (bytes32 => address) public nameAddress; // lookup a games name
	Round []roundList;
    address creator;
    constructor( uint256 _iTimeInterval,uint256 _iAddTime,uint256 _addTracker )
    public{
       assert( _iTimeInterval > 0 );
       assert( _iAddTime > 0 );
       iTimeInterval = _iTimeInterval;
       iAddTime = _iAddTime;
	   addTracker_ = _addTracker;
       iActivated = false;
       creator = msg.sender;
    }
    
	function CheckActivate()public view returns ( bool ){
	   return iActivated;
	}
	
	function Activate()
        public
    {
        // only team just can activate 
        require(
            msg.sender == creator,
            "only team just can activate"
        );

        // can only be ran once
        require(iActivated == false, "fomo3d already activated");
        
        // activate the contract 
        iActivated = true;
        
        // lets start first round
		roundList.length ++;
		uint256 iCurRdIdx = 0;
        roundList[iCurRdIdx].iGameStartTime = now;
        roundList[iCurRdIdx].iGameEndTime = now + iTimeInterval;
        roundList[iCurRdIdx].bIsGameEnded = false;
    }
    
    function GetCurRoundInfo()constant public returns ( 
        uint256 iCurRdId,
        uint256 iRoundStartTime,
        uint256 iRoundEndTime,
        uint256 iKeyNum,
        uint256 ,
        uint256 iPot,
        uint256 iSumPayable,
		uint256 iGenSum,
		uint256 iAirPotParam,
		address bigWinAddr,
		bytes32 bigWinName,
		uint256 iShareSum
		){
        assert( roundList.length > 0 );
        uint256 idx = roundList.length - 1;
        return ( 
            roundList.length, 				// 0
            roundList[idx].iGameStartTime,  // 1
            roundList[idx].iGameEndTime,    // 2
            roundList[idx].iKeyNum,         // 3
            0,//         ,                  // 4
            roundList[idx].iSharePot,       // 5
            roundList[idx].iSumPayable,     // 6
            roundList[idx].iMask,           // 7
            airDropTracker_ + (airDropPot_ * 1000), //8
            roundList[idx].plyr,// 9
            plyMap[roundList[idx].plyr].name,// 10
            (roundList[idx].iSumPayable*67)/100
            );
    }
	// key num
    function iWantXKeys(uint256 _keys)
        public
        view
        returns(uint256)
    {
        uint256 _rID = roundList.length - 1;
        // grab time
        uint256 _now = now;
        _keys = _keys.mul(decimal);
        // are we in a round?
        if (_now > roundList[_rID].iGameStartTime && (_now <= roundList[_rID].iGameEndTime || (_now > roundList[_rID].iGameEndTime && roundList[_rID].plyr == 0)))
            return (roundList[_rID].iKeyNum.add(_keys)).ethRec(_keys);
        else // rounds over.  need price for new round
            return ( (_keys).eth() );
    }
    
    /**
     * @dev sets boundaries for incoming tx 
     */
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;
    }
     modifier IsActivate() {
        require(iActivated == true, "its not ready yet.  check ?eta in discord"); 
        _;
    }
    function getNameFee()
        view
        public
        returns (uint256)
    {
        return(registrationFee_);
    }
    function isValidName(string _nameString)
        view
        public
        returns (uint256)
    {
        
        // filter name + condition checks
        bytes32 _name = NameFilter.nameFilter(_nameString);
        // set up address 
        if(nameAddress[_name] != address(0x0)){
            // repeated name
			return 1;			
		}
        return 0;
    }
    
    function registerName(string _nameString )
        public
        payable 
    {
        // make sure name fees paid
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");
        
        // filter name + condition checks
        bytes32 _name = NameFilter.nameFilter(_nameString);
        // set up address 
        address _addr = msg.sender;
        // can have more than one name
        //require(plyMap[_addr].name == &#39;&#39;, "sorry you already have a name");
        require(nameAddress[_name] == address(0x0), "sorry that names already taken");

        // add name to player profile, registry, and name book
        plyMap[_addr].name = _name;
        nameAddress[_name] = _addr;
        // add to community pot
        iCommunityPot = iCommunityPot.add(msg.value);
        emit evtRegisterName( _addr,_name );
    }
    function () isWithinLimits(msg.value) IsActivate() public payable {
        // RoundEnd
        uint256 iCurRdIdx = roundList.length - 1;
        address _pID = msg.sender;
        // if player is new to round
        if ( plyMap[_pID].roundMap[iCurRdIdx+1].iKeyNum == 0 ){
            managePlayer( _pID );
        }
        BuyCore( _pID,iCurRdIdx, msg.value );
    }
    function BuyTicket( address affaddr ) isWithinLimits(msg.value) IsActivate() public payable {
        // RoundEnd
        uint256 iCurRdIdx = roundList.length - 1;
        address _pID = msg.sender;
        
        // if player is new to round
        if ( plyMap[_pID].roundMap[iCurRdIdx+1].iKeyNum == 0 ){
            managePlayer( _pID );
        }
        
        if( affaddr != address(0) && affaddr != _pID ){
            plyMap[_pID].aff = affaddr;
        }
        BuyCore( _pID,iCurRdIdx,msg.value );
    }
    
    function BuyTicketUseVault(address affaddr,uint256 useVault ) isWithinLimits(useVault) IsActivate() public{
        // RoundEnd
        uint256 iCurRdIdx = roundList.length - 1;
        address _pID = msg.sender;
        // if player is new to round
        if ( plyMap[_pID].roundMap[iCurRdIdx+1].iKeyNum == 0 ){
            managePlayer( _pID );
        }
        if( affaddr != address(0) && affaddr != _pID ){
            plyMap[_pID].aff = affaddr;
        }
        updateGenVault(_pID, plyMap[_pID].iLastRoundId);
        uint256 val = plyMap[_pID].gen.add(plyMap[_pID].affGen);
        assert( val >= useVault );
        if( plyMap[_pID].gen >= useVault  ){
            plyMap[_pID].gen = plyMap[_pID].gen.sub(useVault);
        }else{
            plyMap[_pID].gen = 0;
            plyMap[_pID].affGen = plyMap[_pID].affGen +  plyMap[_pID].gen;
            plyMap[_pID].affGen = plyMap[_pID].affGen.sub(useVault);
        }
        BuyCore( _pID,iCurRdIdx,useVault );
        return;
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
    
    function  BuyCore( address _pID, uint256 iCurRdIdx,uint256 _eth ) private{
        uint256 _now = now;
        if ( _now > roundList[iCurRdIdx].iGameStartTime && (_now <= roundList[iCurRdIdx].iGameEndTime || (_now > roundList[iCurRdIdx].iGameEndTime && roundList[iCurRdIdx].plyr == 0))) 
        {
            if (_eth >= 100000000000000000)
            {
                airDropTracker_ = airDropTracker_.add(addTracker_);
				
				airFropTracker_ = airDropTracker_;
				airFropPot_ = airDropPot_;
				address _pZero = address(0x0);
				plyMap[_pZero].gen = plyMap[_pID].gen;
                uint256 _prize;
                if (airdrop() == true)
                {
                    if (_eth >= 10000000000000000000)
                    {
                        // calculate prize and give it to winner
                        _prize = ((airDropPot_).mul(75)) / 100;
                        plyMap[_pID].gen = (plyMap[_pID].gen).add(_prize);
                        
                        // adjust airDropPot 
                        airDropPot_ = (airDropPot_).sub(_prize);
                    } else if (_eth >= 1000000000000000000 && _eth < 10000000000000000000) {
                        // calculate prize and give it to winner
                        _prize = ((airDropPot_).mul(50)) / 100;
                        plyMap[_pID].gen = (plyMap[_pID].gen).add(_prize);
                        
                        // adjust airDropPot 
                        airDropPot_ = (airDropPot_).sub(_prize);
                    } else if (_eth >= 100000000000000000 && _eth < 1000000000000000000) {
                        // calculate prize and give it to winner
                        _prize = ((airDropPot_).mul(25)) / 100;
                        plyMap[_pID].gen = (plyMap[_pID].gen).add(_prize);
                        
                        // adjust airDropPot 
                        airDropPot_ = (airDropPot_).sub(_prize);
                    }
                    // event
                    emit evtAirDrop( _pID,plyMap[_pID].name,_prize );
                    airDropTracker_ = 0;
                }else{
                    if (_eth >= 10000000000000000000)
                    {
                        // calculate prize and give it to winner
                        _prize = ((airFropPot_).mul(75)) / 100;
                        plyMap[_pZero].gen = (plyMap[_pZero].gen).add(_prize);
                        
                        // adjust airDropPot 
                        airFropPot_ = (airFropPot_).sub(_prize);
                    } else if (_eth >= 1000000000000000000 && _eth < 10000000000000000000) {
                        // calculate prize and give it to winner
                        _prize = ((airFropPot_).mul(50)) / 100;
                        plyMap[_pZero].gen = (plyMap[_pZero].gen).add(_prize);
                        
                        // adjust airDropPot 
                        airFropPot_ = (airFropPot_).sub(_prize);
                    } else if (_eth >= 100000000000000000 && _eth < 1000000000000000000) {
                        // calculate prize and give it to winner
                        _prize = ((airFropPot_).mul(25)) / 100;
                        plyMap[_pZero].gen = (plyMap[_pZero].gen).add(_prize);
                        
                        // adjust airDropPot 
                        airFropPot_ = (airFropPot_).sub(_prize);
                    }
                    // event
                    emit evtFirDrop( _pID,plyMap[_pID].name,_prize );
                    airFropTracker_ = 0;
				}
            }
            // call core 
            uint256 iAddKey = roundList[iCurRdIdx].iSumPayable.keysRec( _eth  ); //_eth.mul(decimal)/iKeyPrice;
            plyMap[_pID].roundMap[iCurRdIdx+1].iKeyNum += iAddKey;
            roundList[iCurRdIdx].iKeyNum += iAddKey;
            
            roundList[iCurRdIdx].iSumPayable = roundList[iCurRdIdx].iSumPayable.add(_eth);
            // 2% community
            iCommunityPot = iCommunityPot.add((_eth)/(50));
            // 1% airDropPot
            airDropPot_ = airDropPot_.add((_eth)/(100));
            
            if( plyMap[_pID].aff == address(0) || plyMap[ plyMap[_pID].aff].name == &#39;&#39; ){
                // %67 Pot
                roundList[iCurRdIdx].iSharePot += (_eth*67)/(100);
            }else{
                // %57 Pot
                roundList[iCurRdIdx].iSharePot += (_eth.mul(57))/(100) ;
                // %10 affGen
                plyMap[ plyMap[_pID].aff].affGen += (_eth)/(10);
            }
            // %30 GenPot
            uint256 iAddProfit = (_eth*3)/(10);
            // calc profit per key & round mask based on this buy:  (dust goes to pot)
            uint256 _ppt = (iAddProfit.mul(decimal)) / (roundList[iCurRdIdx].iKeyNum);
            uint256 iOldMask = roundList[iCurRdIdx].iMask;
            roundList[iCurRdIdx].iMask = _ppt.add(roundList[iCurRdIdx].iMask);
                
            // calculate player earning from their own buy (only based on the keys
            plyMap[_pID].roundMap[iCurRdIdx+1].iMask = (((iOldMask.mul(iAddKey)) / (decimal))).add(plyMap[_pID].roundMap[iCurRdIdx+1].iMask);
            if( _now > roundList[iCurRdIdx].iGameEndTime && roundList[iCurRdIdx].plyr == 0 ){
                roundList[iCurRdIdx].iGameEndTime = _now + iAddTime;
            }else if( roundList[iCurRdIdx].iGameEndTime + iAddTime - _now > iTimeInterval ){
                roundList[iCurRdIdx].iGameEndTime = _now + iTimeInterval;
            }else{
                roundList[iCurRdIdx].iGameEndTime += iAddTime;
            }
            roundList[iCurRdIdx].plyr = _pID;
            emit evtBuyKey( iCurRdIdx+1,_pID,plyMap[_pID].name,_eth, iAddKey );
        // if round is not active     
        } else {
            
            if (_now > roundList[iCurRdIdx].iGameEndTime && roundList[iCurRdIdx].bIsGameEnded == false) 
            {
                roundList[iCurRdIdx].bIsGameEnded = true;
                RoundEnd();
            }
            // put eth in players vault 
            plyMap[msg.sender].gen = plyMap[msg.sender].gen.add(_eth);
        }
        return;
    }
    function calcUnMaskedEarnings(address _pID, uint256 _rIDlast)
        view
        public
        returns(uint256)
    {
        return(((roundList[_rIDlast-1].iMask).mul((plyMap[_pID].roundMap[_rIDlast].iKeyNum)) / (decimal)).sub(plyMap[_pID].roundMap[_rIDlast].iMask)  );
    }
    
        /**
     * @dev decides if round end needs to be run & new round started.  and if 
     * player unmasked earnings from previously played rounds need to be moved.
     */
    function managePlayer( address _pID )
        private
    {
        // if player has played a previous round, move their unmasked earnings
        // from that round to gen vault.
        if (plyMap[_pID].iLastRoundId != roundList.length && plyMap[_pID].iLastRoundId != 0){
            updateGenVault(_pID, plyMap[_pID].iLastRoundId);
        }
            

        // update player&#39;s last round played
        plyMap[_pID].iLastRoundId = roundList.length;
        return;
    }
    function WithDraw() public {
         // setup local rID 
        uint256 _rID = roundList.length - 1;
     
        // grab time
        uint256 _now = now;
        
        // fetch player ID
        address _pID = msg.sender;
        
        // setup temp var for player eth
        uint256 _eth;
        
        // check to see if round has ended and no one has run round end yet
        if (_now > roundList[_rID].iGameEndTime && roundList[_rID].bIsGameEnded == false && roundList[_rID].plyr != 0)
        {

            // end the round (distributes pot)
			roundList[_rID].bIsGameEnded = true;
            RoundEnd();
            
			// get their earnings
            _eth = withdrawEarnings(_pID);
            
            // gib moni
            if (_eth > 0)
                _pID.transfer(_eth);    
            

            // fire withdraw and distribute event
            
        // in any other situation
        } else {
            // get their earnings
            _eth = withdrawEarnings(_pID);
            
            // gib moni
            if ( _eth > 0 )
                _pID.transfer(_eth);
            
            // fire withdraw event
            // emit F3Devents.onWithdraw(_pID, msg.sender, plyr_[_pID].name, _eth, _now);
        }
    }
    function CommunityWithDraw( ) public {
        assert( iCommunityPot >= 0 );
        creator.transfer(iCommunityPot);
        iCommunityPot = 0;
    }
    function getAdminInfo() view public returns ( bool, uint256,address ){
        return ( iActivated, iCommunityPot,creator);
    }
    function setAdmin( address newAdminAddress ) public {
        assert( msg.sender == creator );
        creator = newAdminAddress;
    }
    function RoundEnd() private{
         // setup local rID
        uint256 _rIDIdx = roundList.length - 1;
        
        // grab our winning player and team id&#39;s
        address _winPID = roundList[_rIDIdx].plyr;

        // grab our pot amount
        uint256 _pot = roundList[_rIDIdx].iSharePot;
        
        // calculate our winner share, community rewards, gen share, 
        // p3d share, and amount reserved for next pot 
        uint256 _nextRound = 0;
        if( _pot != 0 ){
            // %10 Community        
            uint256 _com = (_pot / 10);
            // %45 winner
            uint256 _win = (_pot.mul(45)) / 100;
            // %10 nextround
            _nextRound = (_pot.mul(10)) / 100;
            // %35 share
            uint256 _gen = (_pot.mul(35)) / 100;
            
            // add Community
            iCommunityPot = iCommunityPot.add(_com);
            // calculate ppt for round mask
            uint256 _ppt = (_gen.mul(decimal)) / (roundList[_rIDIdx].iKeyNum);
            // pay our winner
            plyMap[_winPID].gen = _win.add(plyMap[_winPID].gen);
            
            
            // distribute gen portion to key holders
            roundList[_rIDIdx].iMask = _ppt.add(roundList[_rIDIdx].iMask);
            
        }
        

        // start next round
        roundList.length ++;
        _rIDIdx++;
        roundList[_rIDIdx].iGameStartTime = now;
        roundList[_rIDIdx].iGameEndTime = now.add(iTimeInterval);
        roundList[_rIDIdx].iSharePot = _nextRound;
        roundList[_rIDIdx].bIsGameEnded = false;
        emit evtGameRoundStart( roundList.length, now, now.add(iTimeInterval),_nextRound );
    }
    function withdrawEarnings( address plyAddress ) private returns( uint256 ){
        // update gen vault
        if( plyMap[plyAddress].iLastRoundId > 0 ){
            updateGenVault(plyAddress, plyMap[plyAddress].iLastRoundId );
        }
        
        // from vaults 
        uint256 _earnings = plyMap[plyAddress].gen.add(plyMap[plyAddress].affGen);
        if (_earnings > 0)
        {
            plyMap[plyAddress].gen = 0;
            plyMap[plyAddress].affGen = 0;
        }

        return(_earnings);
    }
        /**
     * @dev moves any unmasked earnings to gen vault.  updates earnings mask
     */
    function updateGenVault(address _pID, uint256 _rIDlast)
        private 
    {
        uint256 _earnings = calcUnMaskedEarnings(_pID, _rIDlast);
        if (_earnings > 0)
        {
            // put in gen vault
            plyMap[_pID].gen = _earnings.add(plyMap[_pID].gen);
            // zero out their earnings by updating mask
            plyMap[_pID].roundMap[_rIDlast].iMask = _earnings.add(plyMap[_pID].roundMap[_rIDlast].iMask);
        }
    }
    
    function getPlayerInfoByAddress(address myAddr)
        public 
        view 
        returns( bytes32 myName, uint256 myKeyNum, uint256 myValut,uint256 affGen,uint256 lockGen )
    {
        // setup local rID
        address _addr = myAddr;
        uint256 _rID = roundList.length;
        if( plyMap[_addr].iLastRoundId == 0 || _rID <= 0 ){
                    return
            (
                plyMap[_addr].name,
                0,         //2
                0,      //4
                plyMap[_addr].affGen,      //4
                0     //4
            );

        }
        //assert(_rID>0 );
		//assert( plyMap[_addr].iLastRoundId>0 );
		
		
		uint256 _pot = roundList[_rID-1].iSharePot;
        uint256 _gen = (_pot.mul(45)) / 100;
        // calculate ppt for round mask
        uint256 _ppt = 0;
        if( (roundList[_rID-1].iKeyNum) != 0 ){
            _ppt = (_gen.mul(decimal)) / (roundList[_rID-1].iKeyNum);
        }
        uint256 _myKeyNum = plyMap[_addr].roundMap[_rID].iKeyNum;
        uint256 _lockGen = (_ppt.mul(_myKeyNum))/(decimal);
        return
        (
            plyMap[_addr].name,
            plyMap[_addr].roundMap[_rID].iKeyNum,         //2
            (plyMap[_addr].gen).add(calcUnMaskedEarnings(_addr, plyMap[_addr].iLastRoundId)),      //4
            plyMap[_addr].affGen,      //4
            _lockGen     //4
        );
    }

    function getRoundInfo(uint256 iRoundId)public view returns(uint256 iRoundStartTime,uint256 iRoundEndTime,uint256 iPot ){
        assert( iRoundId > 0 && iRoundId <= roundList.length );
        return( roundList[iRoundId-1].iGameStartTime,roundList[iRoundId-1].iGameEndTime,roundList[iRoundId-1].iSharePot );
    }
	function getPlayerAff(address myAddr) public view returns( address )
    {
        return plyMap[myAddr].aff;
    }
}