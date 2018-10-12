pragma solidity ^0.4.24;

/***********************************************************
 * @title SafeMath v0.1.9
 * @dev Math operations with safety checks that throw on error
 * change notes:  original SafeMath library from OpenZeppelin modified by Inventor
 * - added sqrt
 * - added sq
 * - added pwr 
 * - changed asserts to requires with error log outputs
 * - removed div, its useless
 ***********************************************************/
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
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

/***********************************************************
 * F3GDatasets library
 ***********************************************************/
library F3GDatasets {
    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr;         // winner address
        bytes32 winnerName;         // winner name
        uint256 amountWon;          // amount won
        uint256 newPot;             // amount in new pot
        uint256 R3Amount;          // amount distributed to nt
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
        uint256 laff;   // affiliate id used
        uint256 aff1sum;
        uint256 aff2sum;
        uint256 aff3sum;
        uint256 aff4sum;
        uint256 aff5sum;
    }
    struct PlayerRounds {
        uint256 eth;    // eth player has added to round (used for eth limiter)
        uint256 keys;   // keys
        uint256 mask;   // player mask 
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
        uint256 prevres;    // 上一轮或者奖池互换流入本轮的奖金
    }
    struct TeamFee {
        uint256 gen;    // % of buy in thats paid to key holders of current round
        uint256 dev;    // % of buy in thats paid to dev
    }
    struct PotSplit {
        uint256 gen;    // % of pot thats paid to key holders of current round
        uint256 dev;     // % of pot thats paid to dev
    }
}


/***********************************************************
 * F3GKeysCalc library
 ***********************************************************/
library F3GKeysCalc {
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

/***********************************************************
 * F3G contract
 ***********************************************************/
contract F3G {
    using SafeMath              for *;
    using F3GKeysCalc        for uint256;
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
        uint256 R3Amount,
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
        uint256 R3Amount,
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
        uint256 R3Amount,
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
        uint256 R3Amount,
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
    mapping(address => uint256)     private g_users ;
    function initUsers() private {
        g_users[msg.sender] = 9 ;
        
        uint256 pId = G_NowUserId;
        pIDxAddr_[msg.sender] = pId;
        plyr_[pId].addr = msg.sender;
    }
    modifier isAdmin() {
        uint256 role = g_users[msg.sender];
        require((role==9), "Must be admin.");
        _;
    }
    modifier isHuman {
        address _addr = msg.sender;
        uint256 _codeLength;
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "Humans only");
        _;
    }

    address public commAddr_ = address(0x9e27E6b1219dDd2419C278C5B3D74169F6900F4d);
    address public devAddr_ = address(0xe6CE2a354a0BF26B5b383015B7E61701F6adb39C);
    address public affiAddr_ = address(0x08F521636a2B117B554d04dc9E54fa4061161859);

    //合作伙伴
    address public partnerAddr_ = address(0xD4c195777FB7856391390307BAbefA044DaD8DC1);

    bool public activated_ = false;
    modifier isActivated() {
        require(activated_ == true, "its not active yet."); 
        _;
    }
    function activate() isAdmin() public {
        require(address(commAddr_) != address(0x0), "Must setup commAddr_.");
        require(address(devAddr_) != address(0x0), "Must setup devAddr_.");
        require(address(partnerAddr_) != address(0x0), "Must setup partnerAddr_.");
        require(address(affiAddr_) != address(0x0), "Must setup affiAddr_.");
        require(activated_ == false, "Only once");
        activated_ = true ;
        rID_ = 1;
        // ----
        round_[1].strt = now ;                    
        round_[1].end = round_[1].strt + rndMax_;   
    }
    string constant public name   = "Fomo 3G Official";                  // 合约名称
    string constant public symbol = "F3G";                               // 合约符号

    uint256 constant private rndInc_    = 1 minutes;                    // 每购买一个key延迟的时间
    uint256 constant private rndMax_    = 5 hours;                      // 一轮的最长时间

    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "Too little");
        require(_eth <= 100000000000000000000000, "Too much");
        _;    
    }

    uint256 public G_NowUserId = 1000; //当前用户编号
    
    mapping (address => uint256) public pIDxAddr_;  
    mapping (uint256 => F3GDatasets.Player) public plyr_; 
    mapping (uint256 => mapping (uint256 => F3GDatasets.PlayerRounds)) public plyrRnds_;
    uint256 public rID_;                    // 当前游戏轮编号 
    uint256 public airDropPot_;             // 空投小奖池
    uint256 public airDropTracker_ = 0;     // 空投小奖池计数
    mapping (uint256 => F3GDatasets.Round) public round_;
    mapping (uint256 => mapping(uint256 => uint256)) public rndTmEth_;
    mapping (uint256 => F3GDatasets.TeamFee) public fees_; 
    mapping (uint256 => F3GDatasets.PotSplit) public potSplit_;
    
    constructor() public {

		// Team allocation percentages
        // (F3G, dev) + (Pot , Referrals, Community)
            // Referrals / Community rewards are mathematically designed to come from the winner&#39;s share of the pot.
        fees_[0] = F3GDatasets.TeamFee(36,3); //40% to pot, 15% to aff, 3% to com, 2% to 合作伙伴, 1% to air drop pot
        fees_[1] = F3GDatasets.TeamFee(43,3);  //33% to pot, 15% to aff, 3% to com, 2% to 合作伙伴, 1% to air drop pot
        fees_[2] = F3GDatasets.TeamFee(66,3); //10% to pot, 15% to aff, 3% to com, 2% to  合作伙伴, 1% to air drop pot

        // how to split up the final pot based on which team was picked
        // (F3G, dev)
        potSplit_[0] = F3GDatasets.PotSplit(21,3);  //48% to winner, 25% to next round, 3% to com
        potSplit_[1] = F3GDatasets.PotSplit(29,3);   //48% to winner, 17% to next round, 3% to com
        potSplit_[2] = F3GDatasets.PotSplit(36,3);  //48% to winner, 10% to next round, 3% to com

        initUsers();
    }

    function() isActivated() isHuman() isWithinLimits(msg.value) public payable {
        F3GDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 _team = 2;
        buyCore(_pID, 0, _team, _eventData_);
    }
    function buy(uint256 _team) isActivated() isHuman() isWithinLimits(msg.value) public payable {
        F3GDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        uint256 _pID = pIDxAddr_[msg.sender];

        uint256 _affCode = plyr_[_pID].laff;
        
        require(_affCode != 0, "must registration before");

        _team = verifyTeam(_team);
        buyCore(_pID, _affCode, _team, _eventData_);
    }
    
    function reLoadXid(uint256 _team, uint256 _eth) isActivated() isHuman() isWithinLimits(_eth) public {
        F3GDatasets.EventReturns memory _eventData_;
        uint256 _pID = pIDxAddr_[msg.sender];

        uint256 _affCode = plyr_[_pID].laff;

        require(_affCode != 0, "must registration before");

        _team = verifyTeam(_team);
        reLoadCore(_pID, _affCode, _team, _eth, _eventData_);
    }

    function withdraw() isActivated() isHuman() public {
        uint256 _rID = rID_;
        uint256 _now = now;
        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 _eth;
        
        if (_now > round_[_rID].end && (round_[_rID].ended == false) && round_[_rID].plyr != 0){
            F3GDatasets.EventReturns memory _eventData_;
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);
            // get their earnings
            _eth = withdrawEarnings(_pID);
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

            emit onWithdrawAndDistribute(
                msg.sender, 
                plyr_[_pID].name, 
                _eth, 
                _eventData_.compressedData, 
                _eventData_.compressedIDs, 
                _eventData_.winnerAddr, 
                _eventData_.winnerName, 
                _eventData_.amountWon, 
                _eventData_.newPot, 
                _eventData_.R3Amount, 
                _eventData_.genAmount
            );                
        }else{
            _eth = withdrawEarnings(_pID);
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);
            emit onWithdraw(
                _pID, 
                msg.sender, 
                plyr_[_pID].name, 
                _eth, 
                _now
            );
        }
    }

    function register(uint256 _affCode) isHuman() public payable{
        
        require(msg.value == 0, "registration fee is 0 ether, please set the exact amount");
        require(_affCode != 0, "error aff code");
        require(plyr_[_affCode].addr != address(0x0), "error aff code");
        
        G_NowUserId = G_NowUserId.add(1);
        
        address _addr = msg.sender;
        
        pIDxAddr_[_addr] = G_NowUserId;

        plyr_[G_NowUserId].addr = _addr;
        plyr_[G_NowUserId].laff = _affCode;
        
        uint256 _affID1 = _affCode;
        uint256 _affID2 = plyr_[_affID1].laff;
        uint256 _affID3 = plyr_[_affID2].laff;
        uint256 _affID4 = plyr_[_affID3].laff;
        uint256 _affID5 = plyr_[_affID4].laff;
        
        plyr_[_affID1].aff1sum = plyr_[_affID1].aff1sum.add(1);
        plyr_[_affID2].aff2sum = plyr_[_affID2].aff2sum.add(1);
        plyr_[_affID3].aff3sum = plyr_[_affID3].aff3sum.add(1);
        plyr_[_affID4].aff4sum = plyr_[_affID4].aff4sum.add(1);
        plyr_[_affID5].aff5sum = plyr_[_affID5].aff5sum.add(1);

    }
    
    function getBuyPrice() public view  returns(uint256) {  
        uint256 _rID = rID_;
        uint256 _now = now;

        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].keys.add(1000000000000000000)).ethRec(1000000000000000000) );
        else // rounds over.  need price for new round
            return ( 75000000000000 ); // init
    }
    function getTimeLeft() public view returns(uint256) {
        uint256 _rID = rID_;
        uint256 _now = now ;
        if(_rID == 1 && _now < round_[_rID].strt ) return (0);

        if (_now < round_[_rID].end)
            if (_now > round_[_rID].strt)
                return( (round_[_rID].end).sub(_now) );
            else
                return( (round_[_rID].end).sub(_now) );
        else
            return(0);
    }

    function getPlayerVaults(uint256 _pID) public view returns(uint256 ,uint256, uint256) {
        uint256 _rID = rID_;
        if (now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0){
            // if player is winner 
            if (round_[_rID].plyr == _pID){
                uint256 _pot = round_[_rID].pot.add(round_[_rID].prevres);
                return
                (
                    (plyr_[_pID].win).add( ((_pot).mul(48)) / 100 ),
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)   ),
                    plyr_[_pID].aff
                );
            // if player is not the winner
            } else {
                return(
                    plyr_[_pID].win,
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)  ),
                    plyr_[_pID].aff
                );
            }
            
        // if round is still going on, or round has ended and round end has been ran
        } else {
            return(
                plyr_[_pID].win,
                (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),
                plyr_[_pID].aff
            );
        }
    }

    function getPlayerVaultsHelper(uint256 _pID, uint256 _rID) private view returns(uint256) {
        uint256 _pot = round_[_rID].pot.add(round_[_rID].prevres);
        return(  ((((round_[_rID].mask).add(((((_pot).mul(potSplit_[round_[_rID].team].gen)) / 100).mul(1000000000000000000)) / (round_[_rID].keys))).mul(plyrRnds_[_pID][_rID].keys)) / 1000000000000000000)  );
    }
    function getCurrentRoundInfo() public view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, bytes32, uint256, uint256, uint256, uint256, uint256) {
        uint256 _rID = rID_;       
        return
            (
                round_[_rID].ico,             
                _rID,             
                round_[_rID].keys,             
                ((_rID == 1) && (now < round_[_rID].strt) ) ? 0 : round_[_rID].end,
                ((_rID == 1) && (now < round_[_rID].strt) ) ? 0 : round_[_rID].strt,
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
    function getPlayerInfoByAddress(address _addr) public  view  returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256){
        uint256 _rID = rID_;
        if (_addr == address(0)) {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];

        return (
            _pID,
            plyr_[_pID].name,
            plyrRnds_[_pID][_rID].keys,
            plyr_[_pID].win,
            (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),
            plyr_[_pID].aff,
            plyrRnds_[_pID][_rID].eth
        );
    }

    function buyCore(uint256 _pID, uint256 _affID, uint256 _team, F3GDatasets.EventReturns memory _eventData_) private {
        uint256 _rID = rID_;
        uint256 _now = now;
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) {
            core(_rID, _pID, msg.value, _affID, _team, _eventData_);
        }else{
            if (_now > round_[_rID].end && round_[_rID].ended == false) {
                round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);

                _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
                _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;
                emit onBuyAndDistribute(
                    msg.sender, 
                    plyr_[_pID].name, 
                    msg.value, 
                    _eventData_.compressedData, 
                    _eventData_.compressedIDs, 
                    _eventData_.winnerAddr, 
                    _eventData_.winnerName, 
                    _eventData_.amountWon, 
                    _eventData_.newPot, 
                    _eventData_.R3Amount, 
                    _eventData_.genAmount
                );
            }
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }

    function reLoadCore(uint256 _pID, uint256 _affID, uint256 _team, uint256 _eth, F3GDatasets.EventReturns memory _eventData_) private {
        uint256 _rID = rID_;
        uint256 _now = now;
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) {
            plyr_[_pID].gen = withdrawEarnings(_pID).sub(_eth);
            core(_rID, _pID, _eth, _affID, _team, _eventData_);
        }else if (_now > round_[_rID].end && round_[_rID].ended == false) {
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

            emit onReLoadAndDistribute(
                msg.sender, 
                plyr_[_pID].name, 
                _eventData_.compressedData, 
                _eventData_.compressedIDs, 
                _eventData_.winnerAddr, 
                _eventData_.winnerName, 
                _eventData_.amountWon, 
                _eventData_.newPot, 
                _eventData_.R3Amount, 
                _eventData_.genAmount
            );
        }
    }

    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, F3GDatasets.EventReturns memory _eventData_) private{
        if (plyrRnds_[_pID][_rID].keys == 0)
            _eventData_ = managePlayer(_pID, _eventData_);
        if (round_[_rID].eth < 100000000000000000000 && plyrRnds_[_pID][_rID].eth.add(_eth) > 5000000000000000000){
            uint256 _availableLimit = (5000000000000000000).sub(plyrRnds_[_pID][_rID].eth);
            uint256 _refund = _eth.sub(_availableLimit);
            plyr_[_pID].gen = plyr_[_pID].gen.add(_refund);
            _eth = _availableLimit;
        }
        if (_eth > 1000000000) {
            uint256 _keys = (round_[_rID].eth).keysRec(_eth);

            if (_keys >= 1000000000000000000){
                updateTimer(_keys, _rID);
                if (round_[_rID].plyr != _pID)
                    round_[_rID].plyr = _pID;  
                if (round_[_rID].team != _team)
                    round_[_rID].team = _team; 
                _eventData_.compressedData = _eventData_.compressedData + 100;
            }

            if (_eth >= 100000000000000000){
                // > 0.1 ether, 才有空投
                airDropTracker_++;
                if (airdrop() == true){
                    uint256 _prize;
                    if (_eth >= 10000000000000000000){
                        // <= 10 ether
                        _prize = ((airDropPot_).mul(75)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);
                        airDropPot_ = (airDropPot_).sub(_prize);

                        _eventData_.compressedData += 300000000000000000000000000000000;
                    }else if(_eth >= 1000000000000000000 && _eth < 10000000000000000000) {
                        // >= 1 ether and < 10 ether
                        _prize = ((airDropPot_).mul(50)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);

                        airDropPot_ = (airDropPot_).sub(_prize);

                        _eventData_.compressedData += 200000000000000000000000000000000;

                    }else if(_eth >= 100000000000000000 && _eth < 1000000000000000000){
                        // >= 0.1 ether and < 1 ether
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

            // distribute eth
            _eventData_ = distributeExternal(_rID, _pID, _eth, _affID, _team, _eventData_);
            _eventData_ = distributeInternal(_rID, _pID, _eth, _team, _keys, _eventData_);

            endTx(_pID, _team, _eth, _keys, _eventData_);
        }

    }

    function calcUnMaskedEarnings(uint256 _pID, uint256 _rIDlast) private view returns(uint256) {
        return(  (((round_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1000000000000000000)).sub(plyrRnds_[_pID][_rIDlast].mask)  );
    }

    function calcKeysReceived(uint256 _rID, uint256 _eth) public view returns(uint256){
        uint256 _now = now;
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].eth).keysRec(_eth) );
        else // rounds over.  need keys for new round
            return ( (_eth).keys() );
    }

    function iWantXKeys(uint256 _keys) public view returns(uint256) {
        uint256 _rID = rID_;
        uint256 _now = now;

        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].keys.add(_keys)).ethRec(_keys) );
        else // rounds over.  need price for new round
            return ( (_keys).eth() );
    }

    function determinePID(F3GDatasets.EventReturns memory _eventData_) private returns (F3GDatasets.EventReturns) {
        uint256 _pID = pIDxAddr_[msg.sender];

        return _eventData_ ;
    }
    function verifyTeam(uint256 _team) private pure returns (uint256) {
        if (_team < 0 || _team > 2) 
            return(2);
        else
            return(_team);
    }

    function managePlayer(uint256 _pID, F3GDatasets.EventReturns memory _eventData_) private returns (F3GDatasets.EventReturns) {
        if (plyr_[_pID].lrnd != 0)
            updateGenVault(_pID, plyr_[_pID].lrnd);
        
        plyr_[_pID].lrnd = rID_;

        _eventData_.compressedData = _eventData_.compressedData + 10;

        return _eventData_ ;
    }
    function endRound(F3GDatasets.EventReturns memory _eventData_) private returns (F3GDatasets.EventReturns) {
        uint256 _rID = rID_;
        uint256 _winPID = round_[_rID].plyr;
        uint256 _winTID = round_[_rID].team;
        // grab our pot amount
        uint256 _pot = round_[_rID].pot.add(round_[_rID].prevres);

        uint256 _win = (_pot.mul(48)) / 100;
        uint256 _com = (_pot.mul(3)) / 100;
        uint256 _gen = (_pot.mul(potSplit_[_winTID].gen)) / 100;
        uint256 _dev = (_pot.mul(potSplit_[_winTID].dev)) / 100;
        uint256 _res = (((_pot.sub(_win)).sub(_com)).sub(_gen)).sub(_dev);
        // calculate ppt for round mask
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        uint256 _dust = _gen.sub((_ppt.mul(round_[_rID].keys)) / 1000000000000000000);
        if (_dust > 0){
            _gen = _gen.sub(_dust);
            _res = _res.add(_dust);
        }

        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);
        if(_com>0) {
            commAddr_.transfer(_com);
            _com = 0 ;
        }

        if(_dev > 0) {
            devAddr_.transfer(_dev);
        }

        round_[_rID].mask = _ppt.add(round_[_rID].mask);

        _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * 100000000000000000000000000) + (_winTID * 100000000000000000);
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.winnerName = plyr_[_winPID].name;
        _eventData_.amountWon = _win;
        _eventData_.genAmount = _gen;
        _eventData_.R3Amount = 0;
        _eventData_.newPot = _res;
        // 下一轮
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndMax_);
        round_[_rID].prevres = _res;

        return(_eventData_);
    }

    function updateGenVault(uint256 _pID, uint256 _rIDlast) private {
        uint256 _earnings = calcUnMaskedEarnings(_pID, _rIDlast);
        if (_earnings > 0){
            plyr_[_pID].gen = _earnings.add(plyr_[_pID].gen);

            plyrRnds_[_pID][_rIDlast].mask = _earnings.add(plyrRnds_[_pID][_rIDlast].mask);

        }
    }

    function updateTimer(uint256 _keys, uint256 _rID) private {
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

    function airdrop() private  view  returns(bool) {
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
    
    function distributeRef(uint256 _eth, uint256 _affID) private{
        
        uint256 _allaff = (_eth.mul(15)).div(100);
        
        //五级返佣
        uint256 _affID1 = _affID;
        uint256 _affID2 = plyr_[_affID1].laff;
        uint256 _affID3 = plyr_[_affID2].laff;
        uint256 _affID4 = plyr_[_affID3].laff;
        uint256 _affID5 = plyr_[_affID4].laff;
        uint256 _aff = 0;

        if (_affID1 != 0) {   
            _aff = (_eth.mul(5)).div(100);
            _allaff = _allaff.sub(_aff);
            plyr_[_affID1].aff = _aff.add(plyr_[_affID1].aff);
        }

        if (_affID2 != 0) {   
            _aff = (_eth.mul(2)).div(100);
            _allaff = _allaff.sub(_aff);
            plyr_[_affID2].aff = _aff.add(plyr_[_affID2].aff);
        }

        if (_affID3 != 0) {   
            _aff = (_eth.mul(1)).div(100);
            _allaff = _allaff.sub(_aff);
            plyr_[_affID3].aff = _aff.add(plyr_[_affID3].aff);
        }

        if (_affID4 != 0) {   
            _aff = (_eth.mul(2)).div(100);
            _allaff = _allaff.sub(_aff);
            plyr_[_affID4].aff = _aff.add(plyr_[_affID4].aff);
        }

        if (_affID5 != 0) {   
            _aff = (_eth.mul(5)).div(100);
            _allaff = _allaff.sub(_aff);
            plyr_[_affID5].aff = _aff.add(plyr_[_affID5].aff);
        }
        
        if(_allaff > 0 ){
            affiAddr_.transfer(_allaff);
        }          
    }
    
    function distributeExternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, F3GDatasets.EventReturns memory _eventData_) 
        private returns(F3GDatasets.EventReturns){

        uint256 _comm = (_eth.mul(3)).div(100);
        if (_comm > 0) {
            commAddr_.transfer(_comm);
        }
        
        distributeRef(_eth, _affID);

        // partner
        uint256 _partner = (_eth.mul(2)).div(100);
        partnerAddr_.transfer(_partner);

        uint256 _dev = (_eth.mul(fees_[_team].dev)).div(100);
        if(_dev>0){
            devAddr_.transfer(_dev);
        }
        return (_eventData_) ; 

    }

    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _team, uint256 _keys, F3GDatasets.EventReturns memory _eventData_)
        private returns(F3GDatasets.EventReturns) {
        // 持有者的份额 
        uint256 _gen = (_eth.mul(fees_[_team].gen)) / 100;    
        // 空投小奖池 1%
        uint256 _air = (_eth / 100);
        airDropPot_ = airDropPot_.add(_air);
        // 21% = aff airpot etc.
        _eth = _eth.sub(((_eth.mul(21)) / 100).add((_eth.mul(fees_[_team].dev)) / 100));
        // 奖池
        uint256 _pot = _eth.sub(_gen);

        uint256 _dust = updateMasks(_rID, _pID, _gen, _keys);
        if (_dust > 0)
            _gen = _gen.sub(_dust);
        
        round_[_rID].pot = _pot.add(_dust).add(round_[_rID].pot);

        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _pot;

        return(_eventData_);
    }
    
    function updateMasks(uint256 _rID, uint256 _pID, uint256 _gen, uint256 _keys) private returns(uint256) {
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        round_[_rID].mask = _ppt.add(round_[_rID].mask);
        uint256 _pearn = (_ppt.mul(_keys)) / (1000000000000000000);
        plyrRnds_[_pID][_rID].mask = (((round_[_rID].mask.mul(_keys)) / (1000000000000000000)).sub(_pearn)).add(plyrRnds_[_pID][_rID].mask);
        return(_gen.sub((_ppt.mul(round_[_rID].keys)) / (1000000000000000000)));
    }
    function withdrawEarnings(uint256 _pID) private returns(uint256) {
        updateGenVault(_pID, plyr_[_pID].lrnd);
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen).add(plyr_[_pID].aff);
        if (_earnings > 0){
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
            plyr_[_pID].aff = 0;
        }
        return(_earnings);
    }
    function endTx(uint256 _pID, uint256 _team, uint256 _eth, uint256 _keys, F3GDatasets.EventReturns memory _eventData_) private {
        _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000) + (_team * 100000000000000000000000000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + _pID + (rID_ * 10000000000000000000000000000000000000000000000000000);

        emit onEndTx(
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
            _eventData_.R3Amount,
            _eventData_.genAmount,
            _eventData_.potAmount,
            airDropPot_
        );
    }
}