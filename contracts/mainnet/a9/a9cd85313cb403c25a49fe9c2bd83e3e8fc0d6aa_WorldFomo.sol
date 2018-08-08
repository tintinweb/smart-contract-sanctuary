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
contract F3Devents {
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

    // 在购买或重装结束时解雇
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

    // 只要有人退出就会被解雇
    event onWithdraw
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 timeStamp
    );

    // 每当撤军力量结束时，就会被解雇
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

    // (fomo3d免费) 每当玩家尝试一轮又一轮的计时器时就会被解雇
    // 命中零，并导致结束回合
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

    // (fomo3d免费) 每当玩家在圆形时间后尝试重新加载时就会触发
    // 命中零，并导致结束回合.
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

    // 每当联盟会员付款时就会被解雇
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

    // 收到罐子掉期存款
    event onPotSwapDeposit
    (
        uint256 roundID,
        uint256 amountAddedToPot
    );
}

//==============================================================================
//   _ _  _ _|_ _ _  __|_   _ _ _|_    _   .
//  (_(_)| | | | (_|(_ |   _\(/_ | |_||_)  .
//====================================|=========================================

contract modularShort is F3Devents {}

contract WorldFomo is modularShort {
    using SafeMath for *;
    using NameFilter for string;
    using F3DKeysCalcShort for uint256;

    PlayerBookInterface constant private PlayerBook = PlayerBookInterface(0x77abd49884c36193e7d1fccc6898fcdbd9d23ecc);

//==============================================================================
//     _ _  _  |`. _     _ _ |_ | _  _  .
//    (_(_)| |~|~|(_||_|| (_||_)|(/__\  .  (游戏设置)
//=================_|===========================================================
    address private admin = msg.sender;
    string constant public name = "WorldFomo";
    string constant public symbol = "WF";
    uint256 private rndExtra_ = 15 seconds;     // 第一个ICO的长度
    uint256 private rndGap_ = 30 minutes;         // ICO阶段的长度，EOS设定为1年。
    uint256 constant private rndInit_ = 30 minutes;                // 圆计时器从此开始
    uint256 constant private rndInc_ = 10 seconds;              // 购买的每一把钥匙都会给计时器增加很多
    uint256 constant private rndMax_ = 12 hours;                // 圆形计时器的最大长度可以是
//==============================================================================
//     _| _ _|_ _    _ _ _|_    _   .
//    (_|(_| | (_|  _\(/_ | |_||_)  .  (用于存储更改的游戏信息的数据)
//=============================|================================================
    uint256 public airDropPot_;             // 获得空投的人赢得了这个锅的一部分
    uint256 public airDropTracker_ = 0;     // 每次“合格”tx发生时递增。用于确定获胜的空投
    uint256 public rID_;    // 已发生的轮次ID /总轮数
//****************
// 球员数据
//****************
    mapping (address => uint256) public pIDxAddr_;          // （addr => pID）按地址返回玩家ID
    mapping (bytes32 => uint256) public pIDxName_;          // (name => pID）按名称返回玩家ID
    mapping (uint256 => F3Ddatasets.Player) public plyr_;   // (pID => data) 球员数据
    mapping (uint256 => mapping (uint256 => F3Ddatasets.PlayerRounds)) public plyrRnds_;    // (pID => rID => data) 玩家ID和轮次ID的玩家轮数据
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_; // (pID => name => bool）玩家拥有的名字列表。 （用于这样您可以在您拥有的任何名称中更改您的显示名称）
//****************
// 圆形数据
//****************
    mapping (uint256 => F3Ddatasets.Round) public round_;   // (rID => data) 圆形数据
    mapping (uint256 => mapping(uint256 => uint256)) public rndTmEth_;      // (rID => tID => 数据）每个团队的eth，by round id和team id
//****************
// 团队收费数据
//****************
    mapping (uint256 => F3Ddatasets.TeamFee) public fees_;          // (team => fees) 按团队分配费用
    mapping (uint256 => F3Ddatasets.PotSplit) public potSplit_;     // (team => fees) 锅分裂由团队分配
//==============================================================================
//     _ _  _  __|_ _    __|_ _  _  .
//    (_(_)| |_\ | | |_|(_ | (_)|   .  (合同部署时的初始数据设置)
//==============================================================================
    constructor()
        public
    {
        // 团队分配结构
        // 0 = europe
        // 1 = freeforall
        // 2 = china
        // 3 = americas

        // 团队分配百分比
        // (F3D, P3D) + (Pot , Referrals, Community)
            // 介绍人 / 社区奖励在数学上被设计为来自获胜者的底池份额.
        fees_[0] = F3Ddatasets.TeamFee(32,0);   //50% to pot, 15% to aff, 3% to com, 0% to pot swap, 0% to air drop pot
        fees_[1] = F3Ddatasets.TeamFee(45,0);   //37% to pot, 15% to aff, 3% to com, 0% to pot swap, 0% to air drop pot
        fees_[2] = F3Ddatasets.TeamFee(62,0);  //20% to pot, 15% to aff, 3% to com, 0% to pot swap, 0% to air drop pot
        fees_[3] = F3Ddatasets.TeamFee(47,0);   //35% to pot, 15% to aff, 3% to com, 0% to pot swap, 0% to air drop pot

        // 如何根据选择的球队分割最终的底池
        // (F3D, P3D)
        potSplit_[0] = F3Ddatasets.PotSplit(47,0);  //25% to winner, 25% to next round, 3% to com
        potSplit_[1] = F3Ddatasets.PotSplit(47,0);   //25% to winner, 25% to next round, 3% to com
        potSplit_[2] = F3Ddatasets.PotSplit(62,0);  //25% to winner, 10% to next round, 3% to com
        potSplit_[3] = F3Ddatasets.PotSplit(62,0);  //25% to winner, 10% to next round,3% to com
    }
//==============================================================================
//     _ _  _  _|. |`. _  _ _  .
//    | | |(_)(_||~|~|(/_| _\  .  (这些都是安全检查)
//==============================================================================
    /**
     * @dev 用于确保在激活之前没有人可以与合同互动.
     *
     */
    modifier isActivated() {
        require(activated_ == true, "its not ready yet.  check ?eta in discord");
        _;
    }

    /**
     * @dev 防止合同与fomo3d交互
     */
    modifier isHuman() {
        require(msg.sender == tx.origin, "sorry humans only - FOR REAL THIS TIME");
        _;
    }

    /**
     * @dev 设置传入tx的边界
     */
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;
    }

//==============================================================================
//     _    |_ |. _   |`    _  __|_. _  _  _  .
//    |_)|_||_)||(_  ~|~|_|| |(_ | |(_)| |_\  .  (用这些来与合同互动)
//====|=========================================================================
    /**
     * @dev 紧急购买使用最后存储的会员ID和团队潜行
     */
    function()
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        // 设置我们的tx事件数据并确定玩家是否是新手
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        // 获取玩家ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // 买核心
        buyCore(_pID, plyr_[_pID].laff, 2, _eventData_);
    }

    /**
     * @dev 将所有传入的以太坊转换为键.
     * -functionhash- 0x8f38f309 (使用ID作为会员)
     * -functionhash- 0x98a0871d (使用联盟会员的地址)
     * -functionhash- 0xa65b37a1 (使用联盟会员的名称)
     * @param _affCode 获得联盟费用的玩家的ID /地址/名称
     * @param _team 什么球队是球员?
     */
    function buyXid(uint256 _affCode, uint256 _team)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        // 设置我们的tx事件数据并确定玩家是否是新手
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        // 获取玩家ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // 管理会员残差
        // 如果没有给出联盟代码或者玩家试图使用他们自己的代码
        if (_affCode == 0 || _affCode == _pID)
        {
            // 使用最后存储的联盟代码
            _affCode = plyr_[_pID].laff;

        // 如果提供联属代码并且它与先前存储的不同
        } else if (_affCode != plyr_[_pID].laff) {
            // 更新最后一个会员
            plyr_[_pID].laff = _affCode;
        }

        // 验证是否选择了有效的团队
        _team = verifyTeam(_team);

        // 买核心
        buyCore(_pID, _affCode, _team, _eventData_);
    }

    function buyXaddr(address _affCode, uint256 _team)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        // 设置我们的tx事件数据并确定玩家是否是新手
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        // 获取玩家ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // 管理会员残差
        uint256 _affID;
        // 如果没有给出联盟代码或者玩家试图使用他们自己的代码
        if (_affCode == address(0) || _affCode == msg.sender)
        {
            // 使用最后存储的联盟代码
            _affID = plyr_[_pID].laff;

        // 如果是联盟代码
        } else {
            // 从aff Code获取会员ID
            _affID = pIDxAddr_[_affCode];

            // 如果affID与先前存储的不同
            if (_affID != plyr_[_pID].laff)
            {
                // 更新最后一个会员
                plyr_[_pID].laff = _affID;
            }
        }

        // 验证是否选择了有效的团队
        _team = verifyTeam(_team);

        // 买核心
        buyCore(_pID, _affID, _team, _eventData_);
    }

    function buyXname(bytes32 _affCode, uint256 _team)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        // 设置我们的tx事件数据并确定玩家是否是新手
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        // 获取玩家ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // 管理会员残差
        uint256 _affID;
        // 如果没有给出联盟代码或者玩家试图使用他们自己的代码
        if (_affCode == &#39;&#39; || _affCode == plyr_[_pID].name)
        {
            // 使用最后存储的联盟代码
            _affID = plyr_[_pID].laff;

        // 如果是联盟代码
        } else {
            // 从aff Code获取会员ID
            _affID = pIDxName_[_affCode];

            // 如果affID与先前存储的不同
            if (_affID != plyr_[_pID].laff)
            {
                // 更新最后一个会员
                plyr_[_pID].laff = _affID;
            }
        }

        // 验证是否选择了有效的团队
        _team = verifyTeam(_team);

        // 买核心
        buyCore(_pID, _affID, _team, _eventData_);
    }

    /**
     * @dev 基本上与买相同，但不是你发送以太
     * 从您的钱包中，它使用您未提取的收入.
     * -functionhash- 0x349cdcac (使用ID作为会员)
     * -functionhash- 0x82bfc739 (使用联盟会员的地址)
     * -functionhash- 0x079ce327 (使用联盟会员的名称)
     * @param _affCode 获得联盟费用的玩家的ID /地址/名称
     * @param _team 球员在哪支球队？
     * @param _eth 使用的收入金额（余额退回基金库）
     */
    function reLoadXid(uint256 _affCode, uint256 _team, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
        // 设置我们的tx事件数据
        F3Ddatasets.EventReturns memory _eventData_;

        // 获取玩家ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // 管理会员残差
        // 如果没有给出联盟代码或者玩家试图使用他们自己的代码
        if (_affCode == 0 || _affCode == _pID)
        {
            // 使用最后存储的联盟代码
            _affCode = plyr_[_pID].laff;

        // 如果提供联属代码并且它与先前存储的不同
        } else if (_affCode != plyr_[_pID].laff) {
            // 更新最后一个会员
            plyr_[_pID].laff = _affCode;
        }

        // 验证是否选择了有效的团队
        _team = verifyTeam(_team);

        // 重装核心
        reLoadCore(_pID, _affCode, _team, _eth, _eventData_);
    }

    function reLoadXaddr(address _affCode, uint256 _team, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
        // 设置我们的tx事件数据
        F3Ddatasets.EventReturns memory _eventData_;

        // 获取玩家ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // 管理会员残差
        uint256 _affID;
        // 如果没有给出联盟代码或者玩家试图使用他们自己的代码
        if (_affCode == address(0) || _affCode == msg.sender)
        {
            // 使用最后存储的联盟代码
            _affID = plyr_[_pID].laff;

        // 如果是联盟代码
        } else {
            // 从aff Code获取会员ID
            _affID = pIDxAddr_[_affCode];

            // 如果affID与先前存储的不同
            if (_affID != plyr_[_pID].laff)
            {
                // 更新最后一个会员
                plyr_[_pID].laff = _affID;
            }
        }

        // 验证是否选择了有效的团队
        _team = verifyTeam(_team);

        // 重装核心
        reLoadCore(_pID, _affID, _team, _eth, _eventData_);
    }

    function reLoadXname(bytes32 _affCode, uint256 _team, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
        // 设置我们的tx事件数据
        F3Ddatasets.EventReturns memory _eventData_;

        // 获取玩家ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // 管理会员残差
        uint256 _affID;
        // 如果没有给出联盟代码或者玩家试图使用他们自己的代码
        if (_affCode == &#39;&#39; || _affCode == plyr_[_pID].name)
        {
            // 使用最后存储的联盟代码
            _affID = plyr_[_pID].laff;

        // 如果是联盟代码
        } else {
            // 从aff Code获取会员ID
            _affID = pIDxName_[_affCode];

            // 如果affID与先前存储的不同
            if (_affID != plyr_[_pID].laff)
            {
                // 更新最后一个会员
                plyr_[_pID].laff = _affID;
            }
        }

        // 验证是否选择了有效的团队
        _team = verifyTeam(_team);

        // 重装核心
        reLoadCore(_pID, _affID, _team, _eth, _eventData_);
    }

    /**
     * @dev 撤回所有收入.
     * -functionhash- 0x3ccfd60b
     */
    function withdraw()
        isActivated()
        isHuman()
        public
    {
        // 设置本地rID
        uint256 _rID = rID_;

        // 抓住时间
        uint256 _now = now;

        // 获取玩家ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // 为玩家eth设置temp var
        uint256 _eth;

        // 检查圆是否已经结束并且还没有人绕圈结束
        if (_now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
            // 设置我们的tx事件数据
            F3Ddatasets.EventReturns memory _eventData_;

            // 圆形结束（分配锅）
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

            // 得到他们的收入
            _eth = withdrawEarnings(_pID);

            // 给钱
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

            // 构建事件数据
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

            // 火灾撤回和分发事件
            emit F3Devents.onWithdrawAndDistribute
            (
                msg.sender,
                plyr_[_pID].name,
                _eth,
                _eventData_.compressedData,
                _eventData_.compressedIDs,
                _eventData_.winnerAddr,
                _eventData_.winnerName,
                _eventData_.amountWon,
                _eventData_.newPot,
                _eventData_.P3DAmount,
                _eventData_.genAmount
            );

        // 在任何其他情况下
        } else {
            // 得到他们的收入
            _eth = withdrawEarnings(_pID);

            // 给钱
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

            // 消防事件
            emit F3Devents.onWithdraw(_pID, msg.sender, plyr_[_pID].name, _eth, _now);
        }
    }

    /**
     * @dev 使用这些来注册名称。它们只是将注册请求发送给PlayerBook合同的包装器。所以在这里注册与在那里注册是一样的。
     * UI将始终显示您注册的姓氏，但您仍将拥有所有以前注册的名称以用作会员链接。
     * - 必须支付注册费
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
     * @param _affCode 会员ID，地址或推荐您的人的姓名
     * @param _all 如果您希望将信息推送到所有游戏，则设置为true
     * (这可能会耗费大量气体)
     */
    function registerNameXID(string _nameString, uint256 _affCode, bool _all)
        isHuman()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXIDFromDapp.value(_paid)(_addr, _name, _affCode, _all);

        uint256 _pID = pIDxAddr_[_addr];

        // 火灾事件
        emit F3Devents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }

    function registerNameXaddr(string _nameString, address _affCode, bool _all)
        isHuman()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXaddrFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);

        uint256 _pID = pIDxAddr_[_addr];

        // 火灾事件
        emit F3Devents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }

    function registerNameXname(string _nameString, bytes32 _affCode, bool _all)
        isHuman()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXnameFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);

        uint256 _pID = pIDxAddr_[_addr];

        // 火灾事件
        emit F3Devents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }
//==============================================================================
//     _  _ _|__|_ _  _ _  .
//    (_|(/_ |  | (/_| _\  . (用于UI和查看etherscan上的东西)
//=====_|=======================================================================
    /**
     * @dev 退货价格买家将支付下一个个人钥匙.
     * -functionhash- 0x018a25e8
     * @return 购买下一个钥匙的价格（以wei格式）
     */
    function getBuyPrice()
        public
        view
        returns(uint256)
    {
        // 设置本地rID
        uint256 _rID = rID_;

        // 抓住时间
        uint256 _now = now;

        // 我们是一个回合?
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].keys.add(1000000000000000000)).ethRec(1000000000000000000) );
        else // rounds over.  need price for new round
            return ( 75000000000000 ); // init
    }

    /**
     * @dev 返回剩余时间。不要垃圾邮件，你可以从你的节点提供商那里得到你自己
     * -functionhash- 0xc7e284b8
     * @return 时间在几秒钟内
     */
    function getTimeLeft()
        public
        view
        returns(uint256)
    {
        // 设置本地rID
        uint256 _rID = rID_;

        // 抓住时间
        uint256 _now = now;

        if (_now < round_[_rID].end)
            if (_now > round_[_rID].strt + rndGap_)
                return( (round_[_rID].end).sub(_now) );
            else
                return( (round_[_rID].strt + rndGap_).sub(_now) );
        else
            return(0);
    }

    /**
     * @dev 每个金库返回玩家收入
     * -functionhash- 0x63066434
     * @return 赢得金库
     * @return 一般金库
     * @return 会员保险库
     */
    function getPlayerVaults(uint256 _pID)
        public
        view
        returns(uint256 ,uint256, uint256)
    {
        // 设置本地rID
        uint256 _rID = rID_;

        // 如果圆结束了但圆形结束尚未运行（因此合同没有分配奖金）
        if (now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
            // 如果球员是胜利者
            if (round_[_rID].plyr == _pID)
            {
                return
                (
                    (plyr_[_pID].win).add( ((round_[_rID].pot).mul(25)) / 100 ),
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)   ),
                    plyr_[_pID].aff
                );
            // 如果玩家不是赢家
            } else {
                return
                (
                    plyr_[_pID].win,
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)  ),
                    plyr_[_pID].aff
                );
            }

        // 如果圆形仍在继续，或圆形已经结束并且圆形结束已经运行
        } else {
            return
            (
                plyr_[_pID].win,
                (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),
                plyr_[_pID].aff
            );
        }
    }

    /**
     * 坚固不喜欢堆栈限制。这让我们避免那种仇恨
     */
    function getPlayerVaultsHelper(uint256 _pID, uint256 _rID)
        private
        view
        returns(uint256)
    {
        return(  ((((round_[_rID].mask).add(((((round_[_rID].pot).mul(potSplit_[round_[_rID].team].gen)) / 100).mul(1000000000000000000)) / (round_[_rID].keys))).mul(plyrRnds_[_pID][_rID].keys)) / 1000000000000000000)  );
    }

    /**
     * @dev 返回前端所需的所有当前轮次信息
     * -functionhash- 0x747dff42
     * @return 在ICO阶段投资的eth
     * @return 圆的身份
     * @return 圆的总钥匙
     * @return 时间到了
     * @return 时间开始了
     * @return 目前的锅
     * @return 领先的当前球队ID和球员ID
     * @return 领先地址的当前玩家
     * @return 引导名称中的当前玩家
     * @return 鲸鱼为了圆形
     * @return b耳朵为圆形
     * @return 为了回合而进行的
     * @return 公牛队参加比赛
     * @return 空投跟踪器＃＆airdrop pot
     */
    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, bytes32, uint256, uint256, uint256, uint256, uint256)
    {
        // 设置本地rID
        uint256 _rID = rID_;

        return
        (
            round_[_rID].ico,               //0
            _rID,                           //1
            round_[_rID].keys,              //2
            round_[_rID].end,               //3
            round_[_rID].strt,              //4
            round_[_rID].pot,               //5
            (round_[_rID].team + (round_[_rID].plyr * 10)),     //6
            plyr_[round_[_rID].plyr].addr,  //7
            plyr_[round_[_rID].plyr].name,  //8
            rndTmEth_[_rID][0],             //9
            rndTmEth_[_rID][1],             //10
            rndTmEth_[_rID][2],             //11
            rndTmEth_[_rID][3],             //12
            airDropTracker_ + (airDropPot_ * 1000)              //13
        );
    }

    /**
     * @dev 根据地址返回玩家信息。如果没有给出地址，它会
     * use msg.sender
     * -functionhash- 0xee0b5d8b
     * @param _addr 您要查找的播放器的地址
     * @return 玩家ID
     * @return 参赛者姓名
     * @return 密钥拥有（当前轮次）
     * @return 赢得金库
     * @return 一般金库
     * @return 会员保险库
     * @return 球员圆的eth
     */
    function getPlayerInfoByAddress(address _addr)
        public
        view
        returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256)
    {
        // 设置本地rID
        uint256 _rID = rID_;

        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];

        return
        (
            _pID,                               //0
            plyr_[_pID].name,                   //1
            plyrRnds_[_pID][_rID].keys,         //2
            plyr_[_pID].win,                    //3
            (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),       //4
            plyr_[_pID].aff,                    //5
            plyrRnds_[_pID][_rID].eth           //6
        );
    }

//==============================================================================
//     _ _  _ _   | _  _ . _  .
//    (_(_)| (/_  |(_)(_||(_  . (这+工具+计算+模块=我们的软件引擎)
//=====================_|=======================================================
    /**
     * @dev 每当执行买单时，逻辑就会运行。决定如何处理
     * 传入的道德取决于我们是否处于活跃轮次
     */
    function buyCore(uint256 _pID, uint256 _affID, uint256 _team, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
        // 设置本地rID
        uint256 _rID = rID_;

        // 抓住时间
        uint256 _now = now;

        // 如果圆形是活跃的

        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {
            // 致电核心
            core(_rID, _pID, msg.value, _affID, _team, _eventData_);

        // 如果圆形不活跃
        } else {
            // 检查是否需要运行结束轮次
            if (_now > round_[_rID].end && round_[_rID].ended == false)
            {
                // 结束回合（分配锅）并开始新一轮
                round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);

                // 构建事件数据
                _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
                _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

                // 火买和分发事件
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

            // 将eth放入球员保险库中
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }

    /**
     * @dev 每当执行重新加载订单时，逻辑就会运行。决定如何处理
     * 传入的道德取决于我们是否处于活跃轮次
     */
    function reLoadCore(uint256 _pID, uint256 _affID, uint256 _team, uint256 _eth, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
        // 设置本地rID
        uint256 _rID = rID_;

        // 抓住时间
        uint256 _now = now;

        // 如果圆形是活跃的
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {
            // 从所有金库中获取收益并将未使用的金额归还给gen保险库
            // 因为我们使用自定义safemath库。如果玩家，这将抛出
            // 他们试图花更多的时间。
            plyr_[_pID].gen = withdrawEarnings(_pID).sub(_eth);

            // 致电核心
            core(_rID, _pID, _eth, _affID, _team, _eventData_);

        // 如果round不活动并且需要运行end round
        } else if (_now > round_[_rID].end && round_[_rID].ended == false) {
            // end the round (distributes pot) & start new round
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

            // 构建事件数据
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

            // 火买和分发事件
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

    /**
     * @dev 这是在回合生效期间发生的任何购买/重新加载的核心逻辑
     */
    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
        // 如果玩家是新手
        if (plyrRnds_[_pID][_rID].keys == 0)
            _eventData_ = managePlayer(_pID, _eventData_);

        // 早期的道路限制器
        if (round_[_rID].eth < 100000000000000000000 && plyrRnds_[_pID][_rID].eth.add(_eth) > 1000000000000000000)
        {
            uint256 _availableLimit = (1000000000000000000).sub(plyrRnds_[_pID][_rID].eth);
            uint256 _refund = _eth.sub(_availableLimit);
            plyr_[_pID].gen = plyr_[_pID].gen.add(_refund);
            _eth = _availableLimit;
        }

        // 如果留下的eth大于min eth允许（抱歉没有口袋棉绒）
        if (_eth > 1000000000)
        {

            // 铸造新钥匙
            uint256 _keys = (round_[_rID].eth).keysRec(_eth);

            // 如果他们至少买了一把钥匙
            if (_keys >= 1000000000000000000)
            {
            updateTimer(_keys, _rID);

            // 树立新的领导者
            if (round_[_rID].plyr != _pID)
                round_[_rID].plyr = _pID;
            if (round_[_rID].team != _team)
                round_[_rID].team = _team;

            // 将新的领导者布尔设为真
            _eventData_.compressedData = _eventData_.compressedData + 100;
        }


            // 存储空投跟踪器编号（自上次空投以来的购买次数）
            _eventData_.compressedData = _eventData_.compressedData + (airDropTracker_ * 1000);

            // 更新播放器
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);

            // 更新回合
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = _eth.add(round_[_rID].eth);
            rndTmEth_[_rID][_team] = _eth.add(rndTmEth_[_rID][_team]);

            // 分配道德
            _eventData_ = distributeExternal(_rID, _eth, _team, _eventData_);
            _eventData_ = distributeInternal(_rID, _pID, _eth, _affID, _team, _keys, _eventData_);

            // 调用end tx函数来触发结束tx事件。
            endTx(_pID, _team, _eth, _keys, _eventData_);
        }
    }
//==============================================================================
//     _ _ | _   | _ _|_ _  _ _  .
//    (_(_||(_|_||(_| | (_)| _\  .
//==============================================================================
    /**
     * @dev 计算未屏蔽的收入（只计算，不更新掩码）k)
     * @return earnings in wei format
     */
    function calcUnMaskedEarnings(uint256 _pID, uint256 _rIDlast)
        private
        view
        returns(uint256)
    {
        return(  (((round_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1000000000000000000)).sub(plyrRnds_[_pID][_rIDlast].mask)  );
    }

    /**
     * @dev 返回给出一定数量eth的密钥数量.
     * -functionhash- 0xce89c80c
     * @param _rID round ID you want price for
     * @param _eth amount of eth sent in
     * @return keys received
     */
    function calcKeysReceived(uint256 _rID, uint256 _eth)
        public
        view
        returns(uint256)
    {
        // 抓住时间
        uint256 _now = now;

        // 我们是一个回合?
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].eth).keysRec(_eth) );
        else // 转过来。需要新一轮的钥匙
            return ( (_eth).keys() );
    }

    /**
     * @dev 返回X键的当前eth价格。
     * -functionhash- 0xcf808000
     * @param _keys 所需的键数（18位十进制格式）
     * @return 需要发送的eth数量
     */
    function iWantXKeys(uint256 _keys)
        public
        view
        returns(uint256)
    {
        // 设置本地rID
        uint256 _rID = rID_;

        // 抓住时间
        uint256 _now = now;

        // 我们是一个回合?
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].keys.add(_keys)).ethRec(_keys) );
        else // rounds over.  need price for new round
            return ( (_keys).eth() );
    }
//==============================================================================
//    _|_ _  _ | _  .
//     | (_)(_)|_\  .
//==============================================================================
    /**
     * @dev 从姓名合同中接收姓名/球员信息
     */
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

    /**
     * @dev 接收整个玩家名单
     */
    function receivePlayerNameList(uint256 _pID, bytes32 _name)
        external
    {
        require (msg.sender == address(PlayerBook), "your not playerNames contract... hmmm..");
        if(plyrNames_[_pID][_name] == false)
            plyrNames_[_pID][_name] = true;
    }

    /**
     * @dev 获得现有或注册新的pID。当玩家可能是新手时使用此功能
     * @return pID
     */
    function determinePID(F3Ddatasets.EventReturns memory _eventData_)
        private
        returns (F3Ddatasets.EventReturns)
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        // 如果玩家是这个版本的worldfomo的新手
        if (_pID == 0)
        {
            // 从玩家姓名合同中获取他们的玩家ID，姓名和最后一个身份证
            _pID = PlayerBook.getPlayerID(msg.sender);
            bytes32 _name = PlayerBook.getPlayerName(_pID);
            uint256 _laff = PlayerBook.getPlayerLAff(_pID);

            // 设置玩家帐户
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

            // 将新玩家bool设置为true
            _eventData_.compressedData = _eventData_.compressedData + 1;
        }
        return (_eventData_);
    }

    /**
     * @dev 检查以确保用户选择了一个有效的团队。如果没有设置团队
     * 默认（中国）
     */
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

    /**
     * @dev 决定是否需要运行圆形结束并开始新一轮。而如果
     * 需要移动之前玩过的球员未经掩盖的收入
     */
    function managePlayer(uint256 _pID, F3Ddatasets.EventReturns memory _eventData_)
        private
        returns (F3Ddatasets.EventReturns)
    {
        // 如果玩家已经玩过上一轮，则移动他们未经掩盖的收益
        // 从那一轮到生成金库。
        if (plyr_[_pID].lrnd != 0)
            updateGenVault(_pID, plyr_[_pID].lrnd);

        // 更新玩家的最后一轮比赛
        plyr_[_pID].lrnd = rID_;

        // 将连接的圆形bool设置为true
        _eventData_.compressedData = _eventData_.compressedData + 10;

        return(_eventData_);
    }

    /**
     * @dev 结束这一轮。管理支付赢家/拆分锅
     */
    function endRound(F3Ddatasets.EventReturns memory _eventData_)
        private
        returns (F3Ddatasets.EventReturns)
    {
        // 设置本地rID
        uint256 _rID = rID_;

        // 抓住我们的获胜球员和球队ID
        uint256 _winPID = round_[_rID].plyr;
        uint256 _winTID = round_[_rID].team;

        // 抓住我们的锅量
        uint256 _pot = round_[_rID].pot;

        // 计算我们的赢家份额，社区奖励，发行份额，
        // 份额，以及为下一个底池保留的金额
        uint256 _win = (_pot.mul(25)) / 100;
        uint256 _com = (_pot.mul(3)) / 100;
        uint256 _gen = (_pot.mul(potSplit_[_winTID].gen)) / 100;
        uint256 _p3d = (_pot.mul(potSplit_[_winTID].p3d)) / 100;
        uint256 _res = (((_pot.sub(_win)).sub(_com)).sub(_gen)).sub(_p3d);

        // k计算圆形面罩的ppt
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        uint256 _dust = _gen.sub((_ppt.mul(round_[_rID].keys)) / 1000000000000000000);
        if (_dust > 0)
        {
            _gen = _gen.sub(_dust);
            _res = _res.add(_dust);
        }

        // 支付我们的赢家
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);

        // 社区奖励

        admin.transfer(_com);

        // 将gen部分分配给密钥持有者
        round_[_rID].mask = _ppt.add(round_[_rID].mask);

        // 准备事件数据
        _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * 100000000000000000000000000) + (_winTID * 100000000000000000);
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.winnerName = plyr_[_winPID].name;
        _eventData_.amountWon = _win;
        _eventData_.genAmount = _gen;
        _eventData_.P3DAmount = _p3d;
        _eventData_.newPot = _res;

        // 下一轮开始
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_).add(rndGap_);
        round_[_rID].pot = _res;

        return(_eventData_);
    }

    /**
     * @dev moves any unmasked earnings to gen vault.  updates earnings mask
     */
    function updateGenVault(uint256 _pID, uint256 _rIDlast)
        private
    {
        uint256 _earnings = calcUnMaskedEarnings(_pID, _rIDlast);
        if (_earnings > 0)
        {
            // 放入gen库
            plyr_[_pID].gen = _earnings.add(plyr_[_pID].gen);
            // 通过更新面具将收入归零
            plyrRnds_[_pID][_rIDlast].mask = _earnings.add(plyrRnds_[_pID][_rIDlast].mask);
        }
    }

    /**
     * @dev 根据购买的全部密钥数量更新圆形计时器。
     */
    function updateTimer(uint256 _keys, uint256 _rID)
        private
    {
        // 抓住时间
        uint256 _now = now;

        // 根据购买的钥匙数计算时间
        uint256 _newTime;
        if (_now > round_[_rID].end && round_[_rID].plyr == 0)
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(_now);
        else
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(round_[_rID].end);

        // 比较max并设置新的结束时间
        if (_newTime < (rndMax_).add(_now))
            round_[_rID].end = _newTime;
        else
            round_[_rID].end = rndMax_.add(_now);
    }

    /**
     * @dev 生成0-99之间的随机数并检查是否存在
     * 导致空投获胜
     * @return 我们有赢家吗？我们有赢家吗？
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

    /**
     * @dev 根据对com，aff和p3d的费用分配eth
     */
    function distributeExternal(uint256 _rID, uint256 _eth, uint256 _team, F3Ddatasets.EventReturns memory _eventData_)
        private
        returns(F3Ddatasets.EventReturns)
    {
        // 支付3％的社区奖励
        uint256 _com = (_eth.mul(3)) / 100;
        uint256 _p3d;
        if (!address(admin).call.value(_com)())
        {
            _p3d = _com;
            _com = 0;
        }


        // 支付p3d
        _p3d = _p3d.add((_eth.mul(fees_[_team].p3d)) / (100));
        if (_p3d > 0)
        {
            round_[_rID].pot = round_[_rID].pot.add(_p3d);

            // 设置事件数据
            _eventData_.P3DAmount = _p3d.add(_eventData_.P3DAmount);
        }

        return(_eventData_);
    }

    function potSwap()
        external
        payable
    {
        // 设置本地rID
        uint256 _rID = rID_ + 1;

        round_[_rID].pot = round_[_rID].pot.add(msg.value);
        emit F3Devents.onPotSwapDeposit(_rID, msg.value);
    }

    /**
     * @dev 根据对gen和pot的费用分配eth
     */
    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, uint256 _keys, F3Ddatasets.EventReturns memory _eventData_)
        private
        returns(F3Ddatasets.EventReturns)
    {
        // 计算gen份额
        uint256 _gen = (_eth.mul(fees_[_team].gen)) / 100;

        // distribute share to affiliate 15%
        uint256 _aff = (_eth.mul(15)) / 100;

        // 更新道德平衡 (eth = eth - (com share + pot swap share + aff share))
        _eth = _eth.sub(((_eth.mul(18)) / 100).add((_eth.mul(fees_[_team].p3d)) / 100));

        // 计算锅
        uint256 _pot = _eth.sub(_gen);

        // decide what to do with affiliate share of fees
        // affiliate must not be self, and must have a name registered
        if (_affID != _pID && plyr_[_affID].name != &#39;&#39;) {
            plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
            emit F3Devents.onAffiliatePayout(_affID, plyr_[_affID].addr, plyr_[_affID].name, _rID, _pID, _aff, now);
        } else {
            _gen = _gen.add(_aff);
        }

        // 分配gen份额（这就是updateMasks（）所做的）并进行调整
        // 灰尘平衡。
        uint256 _dust = updateMasks(_rID, _pID, _gen, _keys);
        if (_dust > 0)
            _gen = _gen.sub(_dust);

        // 添加eth到pot
        round_[_rID].pot = _pot.add(_dust).add(round_[_rID].pot);

        // 设置事件数据
        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _pot;

        return(_eventData_);
    }

    /**
     * @dev 购买钥匙时更新圆形和玩家的面具
     * @return 灰尘遗留下来
     */
    function updateMasks(uint256 _rID, uint256 _pID, uint256 _gen, uint256 _keys)
        private
        returns(uint256)
    {
        /* 掩盖笔记
            收入面具对人们来说是一个棘手的事情。
            这里要理解的基本内容。将有一个全球性的
            跟踪器基于每轮的每股利润，增加
            相关比例增加份额。

            玩家将有一个额外的面具基本上说“基于
            在回合面具，我的股票，以及我已经撤回了多少，
            还欠我多少钱呢？“
        */

        // 基于此购买的每个键和圆形面具的钙利润:(灰尘进入锅）
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        round_[_rID].mask = _ppt.add(round_[_rID].mask);

        // 计算玩家从他们自己购买的收入（仅基于钥匙
        // 他们刚刚买了）。并更新玩家收入掩
        uint256 _pearn = (_ppt.mul(_keys)) / (1000000000000000000);
        plyrRnds_[_pID][_rID].mask = (((round_[_rID].mask.mul(_keys)) / (1000000000000000000)).sub(_pearn)).add(plyrRnds_[_pID][_rID].mask);

        // 计算并返回灰尘
        return(_gen.sub((_ppt.mul(round_[_rID].keys)) / (1000000000000000000)));
    }

    /**
     * @dev 加上未公开的收入和保险金收入，将它们全部设为0
     * @return wei格式的收益
     */
    function withdrawEarnings(uint256 _pID)
        private
        returns(uint256)
    {
        // 更新gen保险库
        updateGenVault(_pID, plyr_[_pID].lrnd);

        // 来自金库
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen).add(plyr_[_pID].aff);
        if (_earnings > 0)
        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
            plyr_[_pID].aff = 0;
        }

        return(_earnings);
    }

    /**
     * @dev 准备压缩数据并触发事件以进行购买或重新加载tx
     */
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
//==============================================================================
//    (~ _  _    _._|_    .
//    _)(/_(_|_|| | | \/  .
//====================/=========================================================
    /** 合同部署后，它将被停用。这是一次
     * 使用将激活合同的功能。我们这样做是开发者
     * 有时间在网络端设置                           **/
    bool public activated_ = false;
    function activate()
        public
    {
        // 只有团队才能激活
        require(msg.sender == admin, "only admin can activate");


        // 只能跑一次
        require(activated_ == false, "FOMO Free already activated");

        // 激活合同
        activated_ = true;

        // 让我们开始第一轮
        rID_ = 1;
            round_[1].strt = now + rndExtra_ - rndGap_;
            round_[1].end = now + rndInit_ + rndExtra_;
    }
}

//==============================================================================
//   __|_ _    __|_ _  .
//  _\ | | |_|(_ | _\  .
//==============================================================================
library F3Ddatasets {
    //压缩数据密钥
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
    //压缩的ID密钥
    // [77-52][51-26][25-0]
        // 0-25 - pID
        // 26-51 - winPID
        // 52-77 - rID
    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr;         // 获胜者地址
        bytes32 winnerName;         // 获胜者地址
        uint256 amountWon;          // 金额赢了
        uint256 newPot;             // 在新锅中的数量
        uint256 P3DAmount;          // 金额分配给p3d
        uint256 genAmount;          // 金额分配给gen
        uint256 potAmount;          // 加入锅中的量
    }
    struct Player {
        address addr;   // 球员地址
        bytes32 name;   // 参赛者姓名
        uint256 win;    // 赢得金库
        uint256 gen;    // 一般金库
        uint256 aff;    // 会员保险库
        uint256 lrnd;   // 上一轮比赛
        uint256 laff;   // 使用的最后一个会员ID
    }
    struct PlayerRounds {
        uint256 eth;    // 玩家加入回合（用于eth限制器）
        uint256 keys;   // 按键
        uint256 mask;   // 运动员面具
        uint256 ico;    // ICO阶段投资
    }
    struct Round {
        uint256 plyr;   // 领先的玩家的pID
        uint256 team;   // 领导团队的tID
        uint256 end;    // 时间结束/结束
        bool ended;     // 已经运行了圆端函数
        uint256 strt;   // 时间开始了
        uint256 keys;   // 按键
        uint256 eth;    // 总人口
        uint256 pot;    // 罐装（在回合期间）/最终金额支付给获胜者（在回合结束后）
        uint256 mask;   // 全球面具
        uint256 ico;    // 在ICO阶段发送的总eth
        uint256 icoGen; // ICO阶段的gen eth总量
        uint256 icoAvg; // ICO阶段的平均关键价格
    }
    struct TeamFee {
        uint256 gen;    // 支付给本轮关键持有人的购买百分比
        uint256 p3d;    // 支付给p3d持有人的购买百分比
    }
    struct PotSplit {
        uint256 gen;    // 支付给本轮关键持有人的底池百分比
        uint256 p3d;    // 付给p3d持有者的锅的百分比
    }
}

//==============================================================================
//  |  _      _ _ | _  .
//  |<(/_\/  (_(_||(_  .
//=======/======================================================================
library F3DKeysCalcShort {
    using SafeMath for *;
    /**
     * @dev 计算给定X eth时收到的密钥数
     * @param _curEth 合同中的当前eth数量
     * @param _newEth eth被用掉了
     * @return 购买的机票数量
     */
    function keysRec(uint256 _curEth, uint256 _newEth)
        internal
        pure
        returns (uint256)
    {
        return(keys((_curEth).add(_newEth)).sub(keys(_curEth)));
    }

    /**
     * @dev 计算出售X键时收到的eth数量
     * @param _curKeys 当前存在的密钥数量
     * @param _sellKeys 您希望出售的钥匙数量
     * @return 收到的eth数量
     */
    function ethRec(uint256 _curKeys, uint256 _sellKeys)
        internal
        pure
        returns (uint256)
    {
        return((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
    }

    /**
     * @dev 计算给定一定数量的eth会存在多少个密钥
     * @param _eth 合同中的道德
     * @return 将存在的密钥数
     */
    function keys(uint256 _eth)
        internal
        pure
        returns(uint256)
    {
        return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000);
    }

    /**
     * @dev 在给定一些密钥的情况下计算合同中的eth数量
     * @param _keys “契约”中的键数
     * @return 存在的道德
     */
    function eth(uint256 _keys)
        internal
        pure
        returns(uint256)
    {
        return ((78125000).mul(_keys.sq()).add(((149999843750000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
    }
}

//==============================================================================
//  . _ _|_ _  _ |` _  _ _  _  .
//  || | | (/_| ~|~(_|(_(/__\  .
//==============================================================================

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


library NameFilter {
    /**
     * @dev 过滤名称字符串
     * -将大写转换为小写.
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
        // 确保它不以空格开头或以空格结尾
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
     * @dev 给出给定x的平方根.
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