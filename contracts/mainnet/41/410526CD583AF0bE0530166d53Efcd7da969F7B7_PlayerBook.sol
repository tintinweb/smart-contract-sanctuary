pragma solidity ^0.4.24;

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
/*
 * NameFilter library
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
 interface : PlayerBookReceiverInterface
 */
interface PlayerBookReceiverInterface {
    function receivePlayerInfo(uint256 _pID, address _addr, bytes32 _name, uint256 _laff) external;
    function receivePlayerNameList(uint256 _pID, bytes32 _name) external;
}

/**
 contract : PlayerBook
 */
contract PlayerBook{
    /****************************************************************************************** 
     导入的库
     */
    using SafeMath for *;
    using NameFilter for string;
    /******************************************************************************************
     社区地址
     */
    address public communityAddr;
    function initCommunityAddr(address addr) isAdmin() public {
        require(address(addr) != address(0x0), "Empty address not allowed.");
        require(address(communityAddr) == address(0x0), "Community address has been set.");
        communityAddr = addr ;
    }
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
     事件定义
     */
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
    // 注册玩家信息
    struct Player {
        address addr;
        bytes32 name;
        uint256 laff;
        uint256 names;
    }
    /******************************************************************************************  
     注册费用：初始为 0.01 ether
     条件：
     1. 必须是管理员才可以更新
     */
    uint256 public registrationFee_ = 10 finney; 
    function setRegistrationFee(uint256 _fee) isAdmin() public {
        registrationFee_ = _fee ;
    }
    /******************************************************************************************
     注册游戏
     */
    // 注册的游戏列表
    mapping(uint256 => PlayerBookReceiverInterface) public games_;
    // 注册的游戏名称列表
    mapping(address => bytes32) public gameNames_;
    // 注册的游戏ID列表
    mapping(address => uint256) public gameIDs_;
    // 游戏数目
    uint256 public gID_;
    // 判断是否是注册游戏
    modifier isRegisteredGame() {
        require(gameIDs_[msg.sender] != 0);
        _;
    }
    /****************************************************************************************** 
     新增游戏
     条件：
     1. 游戏不存在
     */
    function addGame(address _gameAddress, string _gameNameStr) isAdmin() public {
        require(gameIDs_[_gameAddress] == 0, "Game already registered");
        gID_++;
        bytes32 _name = _gameNameStr.nameFilter();
        gameIDs_[_gameAddress] = gID_;
        gameNames_[_gameAddress] = _name;
        games_[gID_] = PlayerBookReceiverInterface(_gameAddress);
    }
    /****************************************************************************************** 
     玩家信息
     */
    // 玩家数目
    uint256 public pID_;
    // 玩家地址=>玩家ID
    mapping (address => uint256) public pIDxAddr_;
    // 玩家名称=>玩家ID
    mapping (bytes32 => uint256) public pIDxName_;  
    // 玩家ID => 玩家数据
    mapping (uint256 => Player) public plyr_; 
    // 玩家ID => 玩家名称 => 
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_;
    // 玩家ID => 名称编号 => 玩家名称
    mapping (uint256 => mapping (uint256 => bytes32)) public plyrNameList_; 
    /******************************************************************************************
     初始玩家 
     */
     function initPlayers() private {
        pID_ = 0;
     }
    /******************************************************************************************
     判断玩家名字是否有效（是否已经注册过）
     */
    function checkIfNameValid(string _nameStr) public view returns(bool){
        bytes32 _name = _nameStr.nameFilter();
        if (pIDxName_[_name] == 0) return (true);
        else return (false);
    }
    /******************************************************************************************
     构造函数
     */
    constructor() public {
        // 初始化用户
        initUsers() ;
        // 初始化玩家
        initPlayers();
        // 初始化社区基金地址
        communityAddr = address(0x3C07f9f7164Bf72FDBefd9438658fAcD94Ed4439);

    }
    /******************************************************************************************
     注册名字
     _nameString: 名字
     _affCode：推荐人编号
     _all：是否是注册到所有游戏中
     条件：
     1. 是账户地址
     2. 要付费
     */
    function registerNameXID(string _nameString, uint256 _affCode, bool _all) isHuman() public payable{
        // 要求注册费用,不需要付费
        //require (msg.value >= registrationFee_, "You have to pay the name fee");

        bytes32 _name = NameFilter.nameFilter(_nameString);
        address _addr = msg.sender;
        bool _isNewPlayer = determinePID(_addr);
        uint256 _pID = pIDxAddr_[_addr];
        if (_affCode != 0 && _affCode != plyr_[_pID].laff && _affCode != _pID) {
            plyr_[_pID].laff = _affCode;
        }else{
            _affCode = 0;
        }
        registerNameCore(_pID, _addr, _affCode, _name, _isNewPlayer, _all);
    }
    /**
     注册名字
     _nameString: 名字
     _affCode：推荐人地址
     _all：是否是注册到所有游戏中
     条件：
     1. 是账户地址
     2. 要付费
     */
    function registerNameXaddr(string _nameString, address _affCode, bool _all) isHuman() public payable{
        // 要求注册费用,不需要付费
        //require (msg.value >= registrationFee_, "You have to pay the name fee");
        
        bytes32 _name = NameFilter.nameFilter(_nameString);
        address _addr = msg.sender;
        bool _isNewPlayer = determinePID(_addr);
        uint256 _pID = pIDxAddr_[_addr];
        uint256 _affID;
        if (_affCode != address(0) && _affCode != _addr){
            _affID = pIDxAddr_[_affCode];
            if (_affID != plyr_[_pID].laff){
                plyr_[_pID].laff = _affID;
            }
        }
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);
    }
    /**
     注册名字
     _nameString: 名字
     _affCode：推荐人名称
     _all：是否是注册到所有游戏中
     条件：
     1. 是账户地址
     2. 要付费
     */
    function registerNameXname(string _nameString, bytes32 _affCode, bool _all) isHuman() public payable{
        // 要求注册费用,不需要付费
        //require (msg.value >= registrationFee_, "You have to pay the name fee");
        
        bytes32 _name = NameFilter.nameFilter(_nameString);
        address _addr = msg.sender;
        bool _isNewPlayer = determinePID(_addr);
        uint256 _pID = pIDxAddr_[_addr];
        uint256 _affID;
        if (_affCode != "" && _affCode != _name){
            _affID = pIDxName_[_affCode];
            if (_affID != plyr_[_pID].laff){
                plyr_[_pID].laff = _affID;
            }
        }
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);
    }

    /**
     注册
     _pID:          玩家编号
     _addr:         玩家地址
     _affID:        从属
     _name:         名称
    _isNewPlayer:   是否是新玩家
    _all:           是否注册到所有游戏
     */
    function registerNameCore(uint256 _pID, address _addr, uint256 _affID, bytes32 _name, bool _isNewPlayer, bool _all) private {
        // 判断是否已经注册过
        if (pIDxName_[_name] != 0)
            require(plyrNames_[_pID][_name] == true, "That names already taken");
        // 
        plyr_[_pID].name = _name;
        pIDxName_[_name] = _pID;
        if (plyrNames_[_pID][_name] == false) {
            plyrNames_[_pID][_name] = true;
            plyr_[_pID].names++;
            plyrNameList_[_pID][plyr_[_pID].names] = _name;
        }
        // 将注册费用转到社区基金合约账户中
        if(address(this).balance>0){
            if(address(communityAddr) != address(0x0)) {
                communityAddr.transfer(address(this).balance);
            }
        }

        if (_all == true)
            for (uint256 i = 1; i <= gID_; i++)
                games_[i].receivePlayerInfo(_pID, _addr, _name, _affID);
        
        emit onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, msg.value, now);
    }
    /**
     如果是新玩家，则返回真
     */
    function determinePID(address _addr) private returns (bool) {
        if (pIDxAddr_[_addr] == 0){
            pID_++;
            pIDxAddr_[_addr] = pID_;
            plyr_[pID_].addr = _addr;
            return (true) ;
        }else{
            return (false);
        }
    }
    /**
     */
    function addMeToGame(uint256 _gameID) isHuman() public {
        require(_gameID <= gID_, "Game doesn&#39;t exist yet");
        address _addr = msg.sender;
        uint256 _pID = pIDxAddr_[_addr];
        require(_pID != 0, "You dont even have an account");
        uint256 _totalNames = plyr_[_pID].names;
        
        // add players profile and most recent name
        games_[_gameID].receivePlayerInfo(_pID, _addr, plyr_[_pID].name, plyr_[_pID].laff);
        
        // add list of all names
        if (_totalNames > 1)
            for (uint256 ii = 1; ii <= _totalNames; ii++)
                games_[_gameID].receivePlayerNameList(_pID, plyrNameList_[_pID][ii]);
    }

    function addMeToAllGames() isHuman() public {
        address _addr = msg.sender;
        uint256 _pID = pIDxAddr_[_addr];
        require(_pID != 0, "You dont even have an account");
        uint256 _laff = plyr_[_pID].laff;
        uint256 _totalNames = plyr_[_pID].names;
        bytes32 _name = plyr_[_pID].name;
        
        for (uint256 i = 1; i <= gID_; i++){
            games_[i].receivePlayerInfo(_pID, _addr, _name, _laff);
            if (_totalNames > 1)
                for (uint256 ii = 1; ii <= _totalNames; ii++)
                    games_[i].receivePlayerNameList(_pID, plyrNameList_[_pID][ii]);
        }
    }

    function useMyOldName(string _nameString) isHuman() public {
        // filter name, and get pID
        bytes32 _name = _nameString.nameFilter();
        uint256 _pID = pIDxAddr_[msg.sender];
        
        // make sure they own the name 
        require(plyrNames_[_pID][_name] == true, "Thats not a name you own");
        
        // update their current name 
        plyr_[_pID].name = _name;
    }
    /**
     PlayerBookInterface Interface 
     */
    function getPlayerID(address _addr) external returns (uint256){
        determinePID(_addr);
        return (pIDxAddr_[_addr]);
    }

    function getPlayerName(uint256 _pID) external view returns (bytes32){
        return (plyr_[_pID].name);
    }

    function getPlayerLAff(uint256 _pID) external view returns (uint256) {
        return (plyr_[_pID].laff);
    }

    function getPlayerAddr(uint256 _pID) external view returns (address) {
        return (plyr_[_pID].addr);
    }

    function getNameFee() external view returns (uint256){
        return (registrationFee_);
    }
    
    function registerNameXIDFromDapp(address _addr, bytes32 _name, uint256 _affCode, bool _all) 
        isRegisteredGame()
        external payable returns(bool, uint256){
        // 要求注册费用,不需要付费
        //require (msg.value >= registrationFee_, "You have to pay the name fee");

        bool _isNewPlayer = determinePID(_addr);
        uint256 _pID = pIDxAddr_[_addr];
        uint256 _affID = _affCode;
        if (_affID != 0 && _affID != plyr_[_pID].laff && _affID != _pID) {
            plyr_[_pID].laff = _affID;
        } else if (_affID == _pID) {
            _affID = 0;
        }      
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);
        return(_isNewPlayer, _affID);
    }
    //
    function registerNameXaddrFromDapp(address _addr, bytes32 _name, address _affCode, bool _all) 
        isRegisteredGame()
        external payable returns(bool, uint256){
        // 要求注册费用,不需要付费
        //require (msg.value >= registrationFee_, "You have to pay the name fee");

        bool _isNewPlayer = determinePID(_addr);
        uint256 _pID = pIDxAddr_[_addr];
        uint256 _affID;
        if (_affCode != address(0) && _affCode != _addr){
            _affID = pIDxAddr_[_affCode];
            if (_affID != plyr_[_pID].laff){
                plyr_[_pID].laff = _affID;
            }
        }
        
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);
        
        return(_isNewPlayer, _affID);    
    }
    //
    function registerNameXnameFromDapp(address _addr, bytes32 _name, bytes32 _affCode, bool _all) 
        isRegisteredGame()
        external payable returns(bool, uint256){
        // 要求注册费用,不需要付费
        //require (msg.value >= registrationFee_, "You have to pay the name fee");

        bool _isNewPlayer = determinePID(_addr);
        uint256 _pID = pIDxAddr_[_addr];
        uint256 _affID;
        if (_affCode != "" && _affCode != _name){
            _affID = pIDxName_[_affCode];
            if (_affID != plyr_[_pID].laff){
                plyr_[_pID].laff = _affID;
            }
        }
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);
        return(_isNewPlayer, _affID);            
    }
}