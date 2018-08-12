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
 * NameFilter library
 ***********************************************************/
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
/***********************************************************
 * NTech3DDatasets library
 ***********************************************************/
library NTech3DDatasets {
    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr;         // winner address
        bytes32 winnerName;         // winner name
        uint256 amountWon;          // amount won
        uint256 newPot;             // amount in new pot
        uint256 NTAmount;          // amount distributed to nt
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
        uint256 nt;    // % of buy in thats paid to nt holders
    }
    struct PotSplit {
        uint256 gen;    // % of pot thats paid to key holders of current round
        uint256 nt;     // % of pot thats paid to NT foundation 
    }
}
/***********************************************************
 interface : OtherNTech3D
 主要用作奖池互换
 ***********************************************************/
interface OtherNTech3D {
    function potSwap() external payable;
}
/***********************************************************
 * NTech3DKeysCalcLong library
 ***********************************************************/
library NTech3DKeysCalcLong {
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
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 ***********************************************************/
contract ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf( address who ) public view returns (uint value);
    function allowance( address owner, address spender ) public view returns (uint _allowance);

    function transfer( address to, uint value) public returns (bool ok);
    function transferFrom( address from, address to, uint value) public returns (bool ok);
    function approve( address spender, uint value ) public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}
/***********************************************************
 interface : PlayerBookInterface
 ***********************************************************/
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
/***********************************************************
 * NTech3DLong contract
 ***********************************************************/
contract NTech3DLong {
    /****************************************************************************************** 
     导入的库
     */
    using SafeMath              for *;
    using NameFilter            for string;
    using NTech3DKeysCalcLong   for uint256;
    /****************************************************************************************** 
     事件
     */
    // 当玩家注册名字时调用
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
    // 购买完成后或者再次载入时调用
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
        uint256 NTAmount,
        uint256 genAmount,
        uint256 potAmount,
        uint256 airDropPot
    );
    
    // 撤退时调用
    event onWithdraw
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 timeStamp
    );
    
    // 当撤退并且分发时调用
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
        uint256 NTAmount,
        uint256 genAmount
    );
    
    // 当一轮时间过后，有玩家试图购买时调用
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
        uint256 NTAmount,
        uint256 genAmount
    );
    
    //当一轮时间过后，有玩家重载时调用
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
        uint256 NTAmount,
        uint256 genAmount
    );
    
    // 附属账号有支付时调用
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
    
    // 收到奖池存款调用
    event onPotSwapDeposit
    (
        uint256 roundID,
        uint256 amountAddedToPot
    );
    /******************************************************************************************
     合约权限管理
     设计：会设计用户权限管理，
        9 => 管理员角色
        0 => 没有任何权限
     */
    // 用户地址到角色的表
    mapping(address => uint256)     private users ;
    // 初始化
    function initUsers() private {
        // 初始化下列地址帐户为管理员
        users[0x89b2E7Ee504afd522E07F80Ae7b9d4D228AF3fe2] = 9 ;
        users[msg.sender] = 9 ;
    }
    // 是否是管理员
    modifier isAdmin() {
        uint256 role = users[msg.sender];
        require((role==9), "Must be admin.");
        _;
    }
    /******************************************************************************************
     检查是帐户地址还是合约地址   
     */
    modifier isHuman {
        address _addr = msg.sender;
        uint256 _codeLength;
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "Humans only");
        _;
    }
    /******************************************************************************************
     关联合约定义
     */
    // 玩家信息数据库合约
    PlayerBookInterface constant private PlayerBook = PlayerBookInterface(0x410526CD583AF0bE0530166d53Efcd7da969F7B7);
    
    /******************************************************************************************
     社区地址
     NT基金地址
     代币空投的收款地址
     */
    address public communityAddr_;
    address public NTFoundationAddr_;
    address private NTTokenSeller_ ;
    /****************************************************************************************** 
     设置代币地址
     条件：
     1. 地址不能为空
     2. 管理员
    */ 
    ERC20 private NTToken_ ;
    function setNTToken(address addr) isAdmin() public {
        require(address(addr) != address(0x0), "Empty address not allowed.");
        NTToken_ = ERC20(addr);
    }
    /** 
     将游戏合约中的未用完的代币转走
     条件：
     1. 数值大于0
     2. 管理员
     */
    function transfer(address toAddr, uint256 amount) isAdmin() public returns (bool) {
        require(amount > 0, "Must > 0 ");
        NTToken_.transfer(toAddr, amount);
        return true ;
    }
    /******************************************************************************************
     启动
     */
    bool public activated_ = false;
    modifier isActivated() {
        require(activated_ == true, "its not active yet."); 
        _;
    }
    /**
     TODO
     激活游戏
     条件：
     1、要是管理员
     2、要设定代币地址
     3、要设定用作奖池呼唤的游戏地址
     4、只可以激活一次
     */
    function activate() isAdmin() public {
        // 必须设定代币地址
        require(address(NTToken_) != address(0x0), "Must setup NTToken.");
        // 必须设定社区基金地址
        require(address(communityAddr_) != address(0x0), "Must setup CommunityAddr_.");
        // 必须设定购买NT地址
        require(address(NTTokenSeller_) != address(0x0), "Must setup NTTokenSeller.");
        // 必须设定NT基金地址
        require(address(NTFoundationAddr_) != address(0x0), "Must setup NTFoundationAddr.");
        // 只能激活一次
        require(activated_ == false, "Only once");
        //
        activated_ = true ;
        // 初始化开始轮信息
        rID_ = 1;
        round_[1].strt = now ;
        round_[1].end = now + rndMax_;
    }
    /******************************************************************************************
     合约信息
     */
    string constant public name = "NTech 3D Long Official";  // 合约名称
    string constant public symbol = "NT3D";                 // 合约符号
    /**
     */
    uint256 constant private rndInc_    = 1 minutes;                  // 每购买一个key延迟的时间
    uint256 constant private rndMax_    = 6 hours;                     // 一轮的最长时间

    uint256 private ntOf1Ether_ = 30000;                            // 一个以太兑换30000代币
    /******************************************************************************************
     奖池互换
     */
    OtherNTech3D private otherNTech3D_ ;    // 另外一个游戏接口，主要用作奖池呼唤
    /** 
     设定奖池呼唤的另外一个游戏合约地址
     条件
     1. 管理员权限
     2. 之前没有设定过
     3. 设定的地址不能为空
     */
    function setOtherNTech3D(address _otherNTech3D) isAdmin() public {
        require(address(_otherNTech3D) != address(0x0), "Empty address not allowed.");
        require(address(otherNTech3D_) == address(0x0), "OtherNTech3D has been set.");
        otherNTech3D_ = OtherNTech3D(_otherNTech3D);
    }
    /******************************************************************************************
     判断金额
     */
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "Too little");
        require(_eth <= 100000000000000000000000, "Too much");
        _;    
    }

    /******************************************************************************************
     玩家信息
     */
    // 玩家地址 => 玩家ID 
    mapping (address => uint256) public pIDxAddr_;  
    // 玩家名称 => 玩家ID
    mapping (bytes32 => uint256) public pIDxName_;  
    // 玩家ID => 玩家信息
    mapping (uint256 => NTech3DDatasets.Player) public plyr_; 
    // 玩家ID => 游戏轮编号 => 玩家游戏轮信息
    mapping (uint256 => mapping (uint256 => NTech3DDatasets.PlayerRounds)) public plyrRnds_;
    // 玩家ID => 玩家名称 => 
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_;
    /******************************************************************************************
     游戏信息
     */
    uint256 public rID_;                    // 当前游戏轮编号 
    uint256 public airDropPot_;             // 空投小奖池
    uint256 public airDropTracker_ = 0;     // 空投小奖池计数
    // 游戏每轮ID => 游戏轮 
    mapping (uint256 => NTech3DDatasets.Round) public round_;
    // 游戏每轮ID -> 团队ID => ETH
    mapping (uint256 => mapping(uint256 => uint256)) public rndTmEth_;
    /******************************************************************************************
     团队信息
     0 ： 水鲸队
     1 ： 懒熊队
     2 ： 玩蛇队
     3 ： 疯牛队
     */
    // 团队ID => 分配规则 
    mapping (uint256 => NTech3DDatasets.TeamFee) public fees_; 
    // 团队ID => 分配规则
    mapping (uint256 => NTech3DDatasets.PotSplit) public potSplit_;
    /******************************************************************************************
     构造函数
     */
    
    constructor() public {
        // 水鲸：本轮玩家 30%  空投 6%
        fees_[0] = NTech3DDatasets.TeamFee(30,6);
        // 懒熊：本轮玩家 43%  空投 0%
        fees_[1] = NTech3DDatasets.TeamFee(43,0);
        // 玩蛇：本轮玩家 56%  空投 10%
        fees_[2] = NTech3DDatasets.TeamFee(56,10);
        // 疯牛：本轮玩家 43%  空投 8%
        fees_[3] = NTech3DDatasets.TeamFee(43,8);
        // 此轮奖池分配：
        // 水鲸：本轮玩家 25%
        potSplit_[0] = NTech3DDatasets.PotSplit(15,10);
        // 懒熊：本轮玩家 25%
        potSplit_[1] = NTech3DDatasets.PotSplit(25,0); 
        // 玩蛇：本轮玩家 40%
        potSplit_[2] = NTech3DDatasets.PotSplit(20,20);
        // 疯牛：本轮玩家 40%
        potSplit_[3] = NTech3DDatasets.PotSplit(30,10);
        // 初始化用户管理
        initUsers();
        /**
         */
        NTToken_ = ERC20(address(0x09341B5d43a9b2362141675b9276B777470222Be));
        
        communityAddr_ = address(0x3C07f9f7164Bf72FDBefd9438658fAcD94Ed4439);
        NTTokenSeller_ = address(0x531100a6b3686E6140f170B0920962A5D7A2DD25);
        NTFoundationAddr_ = address(0x89b2E7Ee504afd522E07F80Ae7b9d4D228AF3fe2);
    }
    /******************************************************************************************
     购买
     */
    function buyXid(uint256 _affCode, uint256 _team) isActivated() isHuman() isWithinLimits(msg.value) public payable {
        NTech3DDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        uint256 _pID = pIDxAddr_[msg.sender];
        if (_affCode == 0 || _affCode == _pID){
            _affCode = plyr_[_pID].laff;
        }else if (_affCode != plyr_[_pID].laff) {
            plyr_[_pID].laff = _affCode;
        }
        _team = verifyTeam(_team);
        buyCore(_pID, _affCode, _team, _eventData_);
    }
    
    function buyXaddr(address _affCode, uint256 _team) isActivated() isHuman() isWithinLimits(msg.value) public payable {
        NTech3DDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 _affID;
        if (_affCode == address(0) || _affCode == msg.sender){
            _affID = plyr_[_pID].laff;
        }else{
             _affID = pIDxAddr_[_affCode];
             if (_affID != plyr_[_pID].laff){
                 plyr_[_pID].laff = _affID;
             }
        }
         _team = verifyTeam(_team);
         buyCore(_pID, _affID, _team, _eventData_);
    }

    function buyXname(bytes32 _affCode, uint256 _team) isActivated() isHuman() isWithinLimits(msg.value) public payable {
        NTech3DDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 _affID;
        if (_affCode == &#39;&#39; || _affCode == plyr_[_pID].name){
            _affID = plyr_[_pID].laff;
        }else{
            _affID = pIDxName_[_affCode];
            if (_affID != plyr_[_pID].laff){
                plyr_[_pID].laff = _affID;
            }
        }
        _team = verifyTeam(_team);
        buyCore(_pID, _affID, _team, _eventData_);
    }

    function reLoadXid(uint256 _affCode, uint256 _team, uint256 _eth) isActivated() isHuman() isWithinLimits(_eth) public {
        NTech3DDatasets.EventReturns memory _eventData_;
        uint256 _pID = pIDxAddr_[msg.sender];
        if (_affCode == 0 || _affCode == _pID){
            _affCode = plyr_[_pID].laff;
        }else if (_affCode != plyr_[_pID].laff) {
            plyr_[_pID].laff = _affCode;
        }
        _team = verifyTeam(_team);
        reLoadCore(_pID, _affCode, _team, _eth, _eventData_);
    }

    function reLoadXaddr(address _affCode, uint256 _team, uint256 _eth) isActivated() isHuman() isWithinLimits(_eth) public {
        NTech3DDatasets.EventReturns memory _eventData_;
        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 _affID;
        if (_affCode == address(0) || _affCode == msg.sender){
            _affID = plyr_[_pID].laff;
        }else{
            _affID = pIDxAddr_[_affCode];
            if (_affID != plyr_[_pID].laff){
                plyr_[_pID].laff = _affID;
            }
        }
        _team = verifyTeam(_team);
        reLoadCore(_pID, _affID, _team, _eth, _eventData_);
    }

    function reLoadXname(bytes32 _affCode, uint256 _team, uint256 _eth) isActivated() isHuman() isWithinLimits(_eth) public {
        NTech3DDatasets.EventReturns memory _eventData_;
        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 _affID;
        if (_affCode == &#39;&#39; || _affCode == plyr_[_pID].name){
            _affID = plyr_[_pID].laff;
        }else{
            _affID = pIDxName_[_affCode];
            if (_affID != plyr_[_pID].laff){
                plyr_[_pID].laff = _affID;
            }
        }
        _team = verifyTeam(_team);
        reLoadCore(_pID, _affID, _team, _eth, _eventData_);
    }
    /**
     撤退
     */
    function withdraw() isActivated() isHuman() public {
        uint256 _rID = rID_;
        uint256 _now = now;
        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 _eth;
        
        if (_now > round_[_rID].end && (round_[_rID].ended == false) && round_[_rID].plyr != 0){
            NTech3DDatasets.EventReturns memory _eventData_;
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
                _eventData_.NTAmount, 
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
    /******************************************************************************************
     注册
     */
    function registerNameXID(string _nameString, uint256 _affCode, bool _all) isHuman() public payable{
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXIDFromDapp.value(_paid)(_addr, _name, _affCode, _all);
        uint256 _pID = pIDxAddr_[_addr];

        emit onNewName(
            _pID, 
            _addr, 
            _name, 
            _isNewPlayer, 
            _affID, 
            plyr_[_affID].addr, 
            plyr_[_affID].name, 
            _paid, 
            now
        );
    }

    function registerNameXaddr(string _nameString, address _affCode, bool _all) isHuman() public payable{
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXaddrFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);
        
        uint256 _pID = pIDxAddr_[_addr];
        
        emit onNewName(
            _pID, 
            _addr, 
            _name, 
            _isNewPlayer, 
            _affID, 
            plyr_[_affID].addr, 
            plyr_[_affID].name, 
            _paid, 
            now
        );
    }

    function registerNameXname(string _nameString, bytes32 _affCode, bool _all) isHuman() public payable{
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXnameFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);
        
        uint256 _pID = pIDxAddr_[_addr];
        
        emit onNewName(
            _pID, 
            _addr, 
            _name, 
            _isNewPlayer, 
            _affID, 
            plyr_[_affID].addr, 
            plyr_[_affID].name, 
            _paid, 
            now
        );
    }
    /******************************************************************************************
     获取购买价格
     */
    function getBuyPrice() public view  returns(uint256) {  
        uint256 _rID = rID_;
        uint256 _now = now;

        //if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].keys.add(1000000000000000000)).ethRec(1000000000000000000) );
        else // rounds over.  need price for new round
            return ( 75000000000000 ); // init
    }
    /******************************************************************************************
     得到剩余时间
     */
    function getTimeLeft() public view returns(uint256) {
        uint256 _rID = rID_;
        uint256 _now = now;

        if (_now < round_[_rID].end)
            //if (_now > round_[_rID].strt + rndGap_)
            if (_now > round_[_rID].strt)
                return( (round_[_rID].end).sub(_now) );
            else
                //return( (round_[_rID].strt + rndGap_).sub(_now) );
                return( (round_[_rID].end).sub(_now) );
        else
            return(0);
    }

    function getPlayerVaults(uint256 _pID) public view returns(uint256 ,uint256, uint256) {
        uint256 _rID = rID_;
        if (now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0){
            // if player is winner 
            if (round_[_rID].plyr == _pID){
                // Added by Huwei
                uint256 _pot = round_[_rID].pot.add(round_[_rID].prevres);
                return
                (
                    // Fix by huwei
                    //(plyr_[_pID].win).add( ((round_[_rID].pot).mul(48)) / 100 ),
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
        // Fixed by Huwei
        uint256 _pot = round_[_rID].pot.add(round_[_rID].prevres);
        return(  ((((round_[_rID].mask).add(((((_pot).mul(potSplit_[round_[_rID].team].gen)) / 100).mul(1000000000000000000)) / (round_[_rID].keys))).mul(plyrRnds_[_pID][_rID].keys)) / 1000000000000000000)  );
        //return(  ((((round_[_rID].mask).add(((((round_[_rID].pot).mul(potSplit_[round_[_rID].team].gen)) / 100).mul(1000000000000000000)) / (round_[_rID].keys))).mul(plyrRnds_[_pID][_rID].keys)) / 1000000000000000000)  );
    }
    /**
     得到当前此轮信息
     */
    function getCurrentRoundInfo() public view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, bytes32, uint256, uint256, uint256, uint256, uint256) {
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

    function buyCore(uint256 _pID, uint256 _affID, uint256 _team, NTech3DDatasets.EventReturns memory _eventData_) private {
        uint256 _rID = rID_;
        uint256 _now = now;
        //if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) {
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
                    _eventData_.NTAmount, 
                    _eventData_.genAmount
                );
            }
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }

    function reLoadCore(uint256 _pID, uint256 _affID, uint256 _team, uint256 _eth, NTech3DDatasets.EventReturns memory _eventData_) private {
        uint256 _rID = rID_;
        uint256 _now = now;
        //if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) {
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
                _eventData_.NTAmount, 
                _eventData_.genAmount
            );
        }
    }

    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, NTech3DDatasets.EventReturns memory _eventData_) private{
        if (plyrRnds_[_pID][_rID].keys == 0)
            _eventData_ = managePlayer(_pID, _eventData_);
        // 每轮早期的限制 (5 ether 以下)
        // 智能合约收到的总额达到100 ETH之前，每个以太坊地址最多只能购买总额10个ETH的Key。
        if (round_[_rID].eth < 100000000000000000000 && plyrRnds_[_pID][_rID].eth.add(_eth) > 10000000000000000000){
            uint256 _availableLimit = (10000000000000000000).sub(plyrRnds_[_pID][_rID].eth);
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
        // round_[_rIDlast].mask * plyrRnds_[_pID][_rIDlast].keys / 1000000000000000000 - plyrRnds_[_pID][_rIDlast].mask
        return(  (((round_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1000000000000000000)).sub(plyrRnds_[_pID][_rIDlast].mask)  );
    }

    function calcKeysReceived(uint256 _rID, uint256 _eth) public view returns(uint256){
        uint256 _now = now;
        //if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].eth).keysRec(_eth) );
        else // rounds over.  need keys for new round
            return ( (_eth).keys() );
    }

    function iWantXKeys(uint256 _keys) public view returns(uint256) {
        uint256 _rID = rID_;

        uint256 _now = now;

        //if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].keys.add(_keys)).ethRec(_keys) );
        else // rounds over.  need price for new round
            return ( (_keys).eth() );
    }
    /**
     interface : PlayerBookReceiverInterface
     */
    function receivePlayerInfo(uint256 _pID, address _addr, bytes32 _name, uint256 _laff) external {
        require (msg.sender == address(PlayerBook), "Called from PlayerBook only");
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

    function receivePlayerNameList(uint256 _pID, bytes32 _name) external {
        require (msg.sender == address(PlayerBook), "Called from PlayerBook only");
        if(plyrNames_[_pID][_name] == false)
            plyrNames_[_pID][_name] = true;
    }
    /**
     识别玩家
     */
    function determinePID(NTech3DDatasets.EventReturns memory _eventData_) private returns (NTech3DDatasets.EventReturns) {
        uint256 _pID = pIDxAddr_[msg.sender];
        if (_pID == 0){
            _pID = PlayerBook.getPlayerID(msg.sender);
            bytes32 _name = PlayerBook.getPlayerName(_pID);
            uint256 _laff = PlayerBook.getPlayerLAff(_pID);
            pIDxAddr_[msg.sender] = _pID;
            plyr_[_pID].addr = msg.sender;
            if (_name != ""){
                pIDxName_[_name] = _pID;
                plyr_[_pID].name = _name;
                plyrNames_[_pID][_name] = true;
            }
            if (_laff != 0 && _laff != _pID)
                plyr_[_pID].laff = _laff;
            // set the new player bool to true    
            _eventData_.compressedData = _eventData_.compressedData + 1;                
        } 
        return _eventData_ ;
    }
    /**
     识别团队，默认是玩蛇队
     */
    function verifyTeam(uint256 _team) private pure returns (uint256) {
        if (_team < 0 || _team > 3) 
            return(2);
        else
            return(_team);
    }

    function managePlayer(uint256 _pID, NTech3DDatasets.EventReturns memory _eventData_) private returns (NTech3DDatasets.EventReturns) {
        if (plyr_[_pID].lrnd != 0)
            updateGenVault(_pID, plyr_[_pID].lrnd);
        
        plyr_[_pID].lrnd = rID_;

        _eventData_.compressedData = _eventData_.compressedData + 10;

        return _eventData_ ;
    }
    /**
     这轮游戏结束
     */
    function endRound(NTech3DDatasets.EventReturns memory _eventData_) private returns (NTech3DDatasets.EventReturns) {
        uint256 _rID = rID_;
        uint256 _winPID = round_[_rID].plyr;
        uint256 _winTID = round_[_rID].team;
        // grab our pot amount
        // Fixed by Huwei
        //uint256 _pot = round_[_rID].pot;
        uint256 _pot = round_[_rID].pot.add(round_[_rID].prevres);

        // 赢家获取奖池的48%
        uint256 _win = (_pot.mul(48)) / 100;
        // 社区基金获取2%
        uint256 _com = (_pot / 50);
        // 这轮游戏玩家获取的奖金
        uint256 _gen = (_pot.mul(potSplit_[_winTID].gen)) / 100;
        // NT基金获取的奖金
        uint256 _nt = (_pot.mul(potSplit_[_winTID].nt)) / 100;
        // 剩下的奖金
        uint256 _res = (((_pot.sub(_win)).sub(_com)).sub(_gen)).sub(_nt);
        // calculate ppt for round mask
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        uint256 _dust = _gen.sub((_ppt.mul(round_[_rID].keys)) / 1000000000000000000);
        if (_dust > 0){
            _gen = _gen.sub(_dust);
            _res = _res.add(_dust);
        }

        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);
        if(address(communityAddr_)!=address(0x0)) {
            // 将社区基金奖金发到社区奖金地址
            communityAddr_.transfer(_com);
            _com = 0 ;
        }else{
            // 如果没有设置社区地址，那么资金分给下一轮
            _res = SafeMath.add(_res,_com);
            _com = 0 ;
        }
        if(_nt > 0) {
            if(address(NTFoundationAddr_) != address(0x0)) {
                // 分配NT基金奖金
                NTFoundationAddr_.transfer(_nt);
            }else{
                // 如果没有设定，那么资金计入下一轮
                _res = SafeMath.add(_res,_nt);    
                _nt = 0 ; 
            }
        }

        round_[_rID].mask = _ppt.add(round_[_rID].mask);

        _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * 100000000000000000000000000) + (_winTID * 100000000000000000);
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.winnerName = plyr_[_winPID].name;
        _eventData_.amountWon = _win;
        _eventData_.genAmount = _gen;
        _eventData_.NTAmount = 0;
        _eventData_.newPot = _res;
        // 下一轮
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndMax_);
        //round_[_rID].end = now.add(rndInit_).add(rndGap_);
        // Fixed by Huwei
        //round_[_rID].pot = _res;
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
    /**
     计算空投小奖池
     */
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
    /**
     社区基金
     奖池互换
     分享
     空投
     */ 
    function distributeExternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, NTech3DDatasets.EventReturns memory _eventData_) 
        private returns(NTech3DDatasets.EventReturns){
        // 社区基金2%, 如果没有设置社区基金，则这份空投到用户地址
        uint256 _com = _eth / 50;
        // 奖池互换，如果没有设置，进入到社区基金
        uint256 _long = _eth / 100;
        if(address(otherNTech3D_)!=address(0x0)){
            otherNTech3D_.potSwap.value(_long)();
        }else{
            _com = _com.add(_long);
        }
        // 分享，如果没有分享，进入到社区基金
        uint256 _aff = _eth / 10;
        if (_affID != _pID && plyr_[_affID].name != &#39;&#39;) {
            plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
            emit onAffiliatePayout(
                _affID, 
                plyr_[_affID].addr, 
                plyr_[_affID].name, 
                _rID, 
                _pID, 
                _aff, 
                now
            );
        } else {
            _com = _com.add(_aff);
        }
        // 空投（如果没有设置社区基金地址，那么放入空投）
        uint256 _nt = (_eth.mul(fees_[_team].nt)).div(100);
        if(_com>0){
            if(address(communityAddr_)!=address(0x0)) {
                communityAddr_.transfer(_com);
            }else{
                _nt = _nt.add(_com);      
            }
        }
        if(_nt > 0 ){
            // amount = _nt * ntOf1Ether_ ;
            uint256 amount = _nt.mul(ntOf1Ether_);
            _eventData_.NTAmount = amount.add(_eventData_.NTAmount);
            NTToken_.transfer(msg.sender,amount);
            //
            address(NTTokenSeller_).transfer(_nt);
        }

        return (_eventData_) ; 

    }
    /**
     奖池互换
     */
    function potSwap() external payable {
        // 奖池互换放入下一轮
        uint256 _rID = rID_ + 1;
        // Fixed by Huwei
        //round_[_rID].pot = round_[_rID].pot.add(msg.value);
        round_[_rID].prevres = round_[_rID].prevres.add(msg.value);
        emit onPotSwapDeposit(
            _rID, 
            msg.value
        );
    }
    /** 
     持有者
     空投小奖池
     终极奖池
     */ 
    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _team, uint256 _keys, NTech3DDatasets.EventReturns memory _eventData_)
        private returns(NTech3DDatasets.EventReturns) {
        // 持有者的份额 
        uint256 _gen = (_eth.mul(fees_[_team].gen)) / 100;    
        // 空投小奖池 1%
        uint256 _air = (_eth / 100);
        airDropPot_ = airDropPot_.add(_air);
        // 14% = 2% 社区 + 10% 佣金 + 1% 奖池互换 + 1% 空投小奖池
        _eth = _eth.sub(((_eth.mul(14)) / 100).add((_eth.mul(fees_[_team].nt)) / 100));
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
    /**
     撤退时的收益
     */
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
    /**
     完成交易
     */
    function endTx(uint256 _pID, uint256 _team, uint256 _eth, uint256 _keys, NTech3DDatasets.EventReturns memory _eventData_) private {
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
            _eventData_.NTAmount,
            _eventData_.genAmount,
            _eventData_.potAmount,
            airDropPot_
        );
    }
}