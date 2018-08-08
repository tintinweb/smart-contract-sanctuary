pragma solidity ^0.4.24;
/**
*                                        ,   ,
*                                        $,  $,     ,
*                                        "ss.$ss. .s&#39;
*                                ,     .ss$$$$$$$$$$s,
*                                $. s$$$$$$$$$$$$$$`$$Ss
*                                "$$$$$$$$$$$$$$$$$$o$$$       ,
*                               s$$$$$$$$$$$$$$$$$$$$$$$$s,  ,s
*                              s$$$$$$$$$"$$$$$$""""$$$$$$"$$$$$,
*                              s$$$$$$$$$$s""$$$$ssssss"$$$$$$$$"
*                             s$$$$$$$$$$&#39;         `"""ss"$"$s""
*                             s$$$$$$$$$$,              `"""""$  .s$$s
*                             s$$$$$$$$$$$$s,...               `s$$&#39;  `
*                         `ssss$$$$$$$$$$$$$$$$$$$$####s.     .$$"$.   , s-
*                           `""""$$$$$$$$$$$$$$$$$$$$#####$$$$$$"     $.$&#39;
* 祝你成功                        "$$$$$$$$$$$$$$$$$$$$$####s""     .$$$|
*   福    喜喜                        "$$$$$$$$$$$$$$$$$$$$$$$$##s    .$$" $
*                                   $$""$$$$$$$$$$$$$$$$$$$$$$$$$$$$$"   `
*                                  $$"  "$"$$$$$$$$$$$$$$$$$$$$S""""&#39;
*                             ,   ,"     &#39;  $$$$$$$$$$$$$$$$####s
*                             $.          .s$$$$$$$$$$$$$$$$$####"
*                 ,           "$s.   ..ssS$$$$$$$$$$$$$$$$$$$####"
*                 $           .$$$S$$$$$$$$$$$$$$$$$$$$$$$$#####"
*                 Ss     ..sS$$$$$$$$$$$$$$$$$$$$$$$$$$$######""
*                  "$$sS$$$$$$$$$$$$$$$$$$$$$$$$$$$########"
*           ,      s$$$$$$$$$$$$$$$$$$$$$$$$#########""&#39;
*           $    s$$$$$$$$$$$$$$$$$$$$$#######""&#39;      s&#39;         ,
*           $$..$$$$$$$$$$$$$$$$$$######"&#39;       ....,$$....    ,$
*            "$$$$$$$$$$$$$$$######"&#39; ,     .sS$$$$$$$$$$$$$$$$s$$
*              $$$$$$$$$$$$#####"     $, .s$$$$$$$$$$$$$$$$$$$$$$$$s.
*   )          $$$$$$$$$$$#####&#39;      `$$$$$$$$$###########$$$$$$$$$$$.
*  ((          $$$$$$$$$$$#####       $$$$$$$$###"       "####$$$$$$$$$$
*  ) \         $$$$$$$$$$$$####.     $$$$$$###"             "###$$$$$$$$$   s&#39;
* (   )        $$$$$$$$$$$$$####.   $$$$$###"                ####$$$$$$$$s$$&#39;
* )  ( (       $$"$$$$$$$$$$$#####.$$$$$###&#39;                .###$$$$$$$$$$"
* (  )  )   _,$"   $$$$$$$$$$$$######.$$##&#39;                .###$$$$$$$$$$
* ) (  ( \.         "$$$$$$$$$$$$$#######,,,.          ..####$$$$$$$$$$$"
*(   )$ )  )        ,$$$$$$$$$$$$$$$$$$####################$$$$$$$$$$$"
*(   ($$  ( \     _sS"  `"$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$S$$,
* )  )$$$s ) )  .      .   `$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$"&#39;  `$$
*  (   $$$Ss/  .$,    .$,,s$$$$$$##S$$$$$$$$$$$$$$$$$$$$$$$$S""        &#39;
*    \)_$$$$$$$$$$$$$$$$$$$$$$$##"  $$        `$$.        `$$.
*        `"S$$$$$$$$$$$$$$$$$#"      $          `$          `$
*            `"""""""""""""&#39;         &#39;           &#39;           &#39;
*/

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
    uint256 public registrationFee_ = 10 finney;            // 注册名称的价格
    mapping(uint256 => PlayerBookReceiverInterface) public games_;  // 映射我们的游戏界面，将您的帐户信息发送到游戏
    mapping(address => bytes32) public gameNames_;          // 查找游戏名称
    mapping(address => uint256) public gameIDs_;            // 查找游戏ID
    uint256 public gID_;        // 游戏总数
    uint256 public pID_;        // 球员总数
    mapping (address => uint256) public pIDxAddr_;          // (addr => pID) 按地址返回玩家ID
    mapping (bytes32 => uint256) public pIDxName_;          // (name => pID) 按名称返回玩家ID
    mapping (uint256 => Player) public plyr_;               // (pID => data) 球员数据
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_; // (pID => name => bool) 玩家拥有的名字列表。 （用于这样你就可以改变你的显示名称，而不管你拥有的任何名字）
    mapping (uint256 => mapping (uint256 => bytes32)) public plyrNameList_; // (pID => nameNum => name) 玩家拥有的名字列表
    struct Player {
        address addr;
        bytes32 name;
        uint256 laff;
        uint256 names;
    }
//==============================================================================
//     _ _  _  __|_ _    __|_ _  _  .
//    (_(_)| |_\ | | |_|(_ | (_)|   .  （合同部署时的初始数据设置）
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
//    | | |(_)(_||~|~|(/_| _\  .  （这些是安全检查）
//==============================================================================
    /**
     * @dev 防止合同与worldfomo交互
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
    // 只要玩家注册了名字就会被解雇
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
//    (_|(/_ |  | (/_| _\  . （用于UI和查看etherscan上的内容）
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
//    |_)|_||_)||(_  ~|~|_|| |(_ | |(_)| |_\  .  （使用这些与合同互动）
//====|=========================================================================
    /**
     * @dev 注册一个名字。 UI将始终显示您注册的姓氏。
     * 但您仍将拥有所有以前注册的名称以用作联属会员
     * - 必须支付注册费。
     * - 名称必须是唯一的
     * - 名称将转换为小写
     * - 名称不能以空格开头或结尾
     * - 连续不能超过1个空格
     * - 不能只是数字
     * - 不能以0x开头
     * - name必须至少为1个字符
     * - 最大长度为32个字符
     * - 允许的字符：a-z，0-9和空格
     * -functionhash- 0x921dec21 (使用ID作为会员)
     * -functionhash- 0x3ddd4698 (使用联盟会员的地址)
     * -functionhash- 0x685ffd83 (使用联盟会员的名称)
     * @param _nameString 球员想要的名字
     * @param _affCode 会员ID，地址或谁提到你的名字
     * @param _all 如果您希望将信息推送到所有游戏，则设置为true
     * (这可能会耗费大量气体)
     */
    function registerNameXID(string _nameString, uint256 _affCode, bool _all)
        isHuman()
        public
        payable
    {
        // 确保支付名称费用
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        // 过滤器名称+条件检查
        bytes32 _name = NameFilter.nameFilter(_nameString);

        // 设置地址
        address _addr = msg.sender;

        // 设置我们的tx事件数据并确定玩家是否是新手
        bool _isNewPlayer = determinePID(_addr);

        // 获取玩家ID
        uint256 _pID = pIDxAddr_[_addr];

        // 管理会员残差
        // 如果没有给出联盟代码，则没有给出新的联盟代码，或者
        // 玩家试图使用自己的pID作为联盟代码
        if (_affCode != 0 && _affCode != plyr_[_pID].laff && _affCode != _pID)
        {
            // 更新最后一个会员
            plyr_[_pID].laff = _affCode;
        } else if (_affCode == _pID) {
            _affCode = 0;
        }

        // 注册名称
        registerNameCore(_pID, _addr, _affCode, _name, _isNewPlayer, _all);
    }

    function registerNameXaddr(string _nameString, address _affCode, bool _all)
        isHuman()
        public
        payable
    {
        // 确保支付名称费用
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        // 过滤器名称+条件检查
        bytes32 _name = NameFilter.nameFilter(_nameString);

        // 设置地址
        address _addr = msg.sender;

        // 设置我们的tx事件数据并确定玩家是否是新手
        bool _isNewPlayer = determinePID(_addr);

        // 获取玩家ID
        uint256 _pID = pIDxAddr_[_addr];

        // 管理会员残差
        // 如果没有给出联盟代码或者玩家试图使用他们自己的代码
        uint256 _affID;
        if (_affCode != address(0) && _affCode != _addr)
        {
            // 从aff Code获取会员ID
            _affID = pIDxAddr_[_affCode];

            // 如果affID与先前存储的不同
            if (_affID != plyr_[_pID].laff)
            {
                // 更新最后一个会员
                plyr_[_pID].laff = _affID;
            }
        }

        // 注册名称
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);
    }

    function registerNameXname(string _nameString, bytes32 _affCode, bool _all)
        isHuman()
        public
        payable
    {
        // 确保支付名称费用
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        // 过滤器名称+条件检查
        bytes32 _name = NameFilter.nameFilter(_nameString);

        // 设置地址
        address _addr = msg.sender;

        // 设置我们的tx事件数据并确定玩家是否是新手
        bool _isNewPlayer = determinePID(_addr);

        // 获取玩家ID
        uint256 _pID = pIDxAddr_[_addr];

        // 管理会员残差
        // 如果没有给出联盟代码或者玩家试图使用他们自己的代码
        uint256 _affID;
        if (_affCode != "" && _affCode != _name)
        {
            // 从aff Code获取会员ID
            _affID = pIDxName_[_affCode];

            // 如果affID与先前存储的不同
            if (_affID != plyr_[_pID].laff)
            {
                // 更新最后一个会员
                plyr_[_pID].laff = _affID;
            }
        }

        // 注册名称
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);
    }

    /**
     * @dev 玩家，如果您在游戏发布之前注册了个人资料，或者
     * 注册时将all bool设置为false，使用此功能进行推送
     * 你对一场比赛的个人资料。另外，如果你更新了你的名字，那么你
     * 可以使用此功能将您的名字推送到您选择的游戏中。
     * -functionhash- 0x81c5b206
     * @param _gameID 游戏ID
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

        // 添加玩家个人资料和最新名称
        games_[_gameID].receivePlayerInfo(_pID, _addr, plyr_[_pID].name, plyr_[_pID].laff);

        // 添加所有名称的列表
        if (_totalNames > 1)
            for (uint256 ii = 1; ii <= _totalNames; ii++)
                games_[_gameID].receivePlayerNameList(_pID, plyrNameList_[_pID][ii]);
    }

    /**
     * @dev 玩家，使用此功能将您的玩家资料推送到所有已注册的游戏。
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
     * @dev 玩家使用它来改回你的一个旧名字。小费，你会的
     * 仍然需要将该信息推送到现有游戏。
     * -functionhash- 0xb9291296
     * @param _nameString 您要使用的名称
     */
    function useMyOldName(string _nameString)
        isHuman()
        public
    {
        // 过滤器名称，并获取pID
        bytes32 _name = _nameString.nameFilter();
        uint256 _pID = pIDxAddr_[msg.sender];

        // 确保他们拥有这个名字
        require(plyrNames_[_pID][_name] == true, "umm... thats not a name you own");

        // 更新他们当前的名字
        plyr_[_pID].name = _name;
    }

//==============================================================================
//     _ _  _ _   | _  _ . _  .
//    (_(_)| (/_  |(_)(_||(_  .
//=====================_|=======================================================
    function registerNameCore(uint256 _pID, address _addr, uint256 _affID, bytes32 _name, bool _isNewPlayer, bool _all)
        private
    {
        // 如果已使用名称，则要求当前的msg发件人拥有该名称
        if (pIDxName_[_name] != 0)
            require(plyrNames_[_pID][_name] == true, "sorry that names already taken");

        // 为播放器配置文件，注册表和名称簿添加名称
        plyr_[_pID].name = _name;
        pIDxName_[_name] = _pID;
        if (plyrNames_[_pID][_name] == false)
        {
            plyrNames_[_pID][_name] = true;
            plyr_[_pID].names++;
            plyrNameList_[_pID][plyr_[_pID].names] = _name;
        }

        // 注册费直接归于社区奖励
        admin.transfer(address(this).balance);

        // 将玩家信息推送到游戏
        if (_all == true)
            for (uint256 i = 1; i <= gID_; i++)
                games_[i].receivePlayerInfo(_pID, _addr, _name, _affID);

        // 火灾事件
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

            // 将新玩家bool设置为true
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
        // 确保支付名称费用
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        // 设置我们的tx事件数据并确定玩家是否是新手
        bool _isNewPlayer = determinePID(_addr);

        // 获取玩家ID
        uint256 _pID = pIDxAddr_[_addr];

        // 管理会员残差
        // 如果没有给出联盟代码，则没有给出新的联盟代码，或者
        // 玩家试图使用自己的pID作为联盟代码
        uint256 _affID = _affCode;
        if (_affID != 0 && _affID != plyr_[_pID].laff && _affID != _pID)
        {
            // 更新最后一个会员
            plyr_[_pID].laff = _affID;
        } else if (_affID == _pID) {
            _affID = 0;
        }

        // 注册名称
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);

        return(_isNewPlayer, _affID);
    }
    function registerNameXaddrFromDapp(address _addr, bytes32 _name, address _affCode, bool _all)
        isRegisteredGame()
        external
        payable
        returns(bool, uint256)
    {
        // 确保支付名称费用
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        // 设置我们的tx事件数据并确定玩家是否是新手
        bool _isNewPlayer = determinePID(_addr);

        // 获取玩家ID
        uint256 _pID = pIDxAddr_[_addr];

        // 管理会员残差
        // 如果没有给出联盟代码或者玩家试图使用他们自己的代码
        uint256 _affID;
        if (_affCode != address(0) && _affCode != _addr)
        {
            // 从aff Code获取会员ID
            _affID = pIDxAddr_[_affCode];

            // 如果affID与先前存储的不同
            if (_affID != plyr_[_pID].laff)
            {
                // 更新最后一个会员
                plyr_[_pID].laff = _affID;
            }
        }

        // 注册名称
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);

        return(_isNewPlayer, _affID);
    }
    function registerNameXnameFromDapp(address _addr, bytes32 _name, bytes32 _affCode, bool _all)
        isRegisteredGame()
        external
        payable
        returns(bool, uint256)
    {
        // 确保支付名称费用
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        // 设置我们的tx事件数据并确定玩家是否是新手
        bool _isNewPlayer = determinePID(_addr);

        // 获取玩家ID
        uint256 _pID = pIDxAddr_[_addr];

        // 管理会员残差
        // 如果没有给出联盟代码或者玩家试图使用他们自己的代码
        uint256 _affID;
        if (_affCode != "" && _affCode != _name)
        {
            // 从aff Code获取会员ID
            _affID = pIDxName_[_affCode];

            // 如果affID与先前存储的不同
            if (_affID != plyr_[_pID].laff)
            {
                // 更新最后一个会员
                plyr_[_pID].laff = _affID;
            }
        }

        // 注册名称
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
     * @dev 过滤名称字符串
     * -将大写转换为小写。
     * -确保它不以空格开始/结束
     * -确保它不包含连续的多个空格
     * -不能只是数字
     * -不能以0x开头
     * -将字符限制为A-Z，a-z，0-9和空格。
     * @return 以字节32格式重新处理的字符串
     */
    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;

        //对不起限于32个字符
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
        //确保它不以空格开头或以空格结尾
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
        // 确保前两个字符不是0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }

        // 创建一个bool来跟踪我们是否有非数字字符
        bool _hasNonNumber;

        // 转换和检查
        for (uint256 i = 0; i < _length; i++)
        {
            // 如果它的大写A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                // 转换为小写a-z
                _temp[i] = byte(uint(_temp[i]) + 32);

                // 我们有一个非数字
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                    // 要求角色是一个空间
                    _temp[i] == 0x20 ||
                    // 或小写a-z
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                    // 或0-9
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                // 确保连续两行不是空格
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");

                // 看看我们是否有一个数字以外的字符
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
 * @dev 带有安全检查的数学运算会引发错误
 * - 添加 sqrt
 * - 添加 sq
 * - 添加 pwr
 * - 将断言更改为需要带有错误日志输出
 * - 删除div，它没用
 */
library SafeMath {

    /**
    * @dev 将两个数字相乘，抛出溢出。
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
    * @dev 减去两个数字，在溢出时抛出（即，如果减数大于减数）。
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
    * @dev 添加两个数字，溢出时抛出。
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
     * @dev 给出给定x的平方根。
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
     * @dev 给广场。将x乘以x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }

    /**
     * @dev x到y的力量
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