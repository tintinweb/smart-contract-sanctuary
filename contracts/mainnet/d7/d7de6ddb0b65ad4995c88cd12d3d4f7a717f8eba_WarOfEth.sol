pragma solidity 0.4.24;

/* 
*  __      __  ______  ____        _____   ____        ____    ______  __  __
* /\ \  __/\ \/\  _  \/\  _`\     /\  __`\/\  _`\     /\  _`\ /\__  _\/\ \/\ \
* \ \ \/\ \ \ \ \ \L\ \ \ \L\ \   \ \ \/\ \ \ \L\_\   \ \ \L\_\/_/\ \/\ \ \_\ \
*  \ \ \ \ \ \ \ \  __ \ \ ,  /    \ \ \ \ \ \  _\/    \ \  _\L  \ \ \ \ \  _  \
*   \ \ \_/ \_\ \ \ \/\ \ \ \\ \    \ \ \_\ \ \ \/      \ \ \L\ \ \ \ \ \ \ \ \ \
*    \ `\___x___/\ \_\ \_\ \_\ \_\   \ \_____\ \_\       \ \____/  \ \_\ \ \_\ \_\
*     &#39;\/__//__/  \/_/\/_/\/_/\/ /    \/_____/\/_/        \/___/    \/_/  \/_/\/_/
* 
*             _____  _____   __  __   ____    ____
*            /\___ \/\  __`\/\ \/\ \ /\  _`\ /\  _`\
*    __      \/__/\ \ \ \/\ \ \ \/&#39;/&#39;\ \ \L\_\ \ \L\ \         __      __      ___ ___      __
*  /&#39;__`\       _\ \ \ \ \ \ \ \ , <  \ \  _\L\ \ ,  /       /&#39;_ `\  /&#39;__`\  /&#39; __` __`\  /&#39;__`\
* /\ \L\.\_    /\ \_\ \ \ \_\ \ \ \\`\ \ \ \L\ \ \ \\ \     /\ \L\ \/\ \L\.\_/\ \/\ \/\ \/\  __/
* \ \__/.\_\   \ \____/\ \_____\ \_\ \_\\ \____/\ \_\ \_\   \ \____ \ \__/.\_\ \_\ \_\ \_\ \____\
*  \/__/\/_/    \/___/  \/_____/\/_/\/_/ \/___/  \/_/\/ /    \/___L\ \/__/\/_/\/_/\/_/\/_/\/____/
*                                                              /\____/
*                                                              \_/__/
*/

contract WarOfEth {
    using SafeMath for *;
    using NameFilter for string;
    using WoeKeysCalc for uint256;

    //==============
    // EVENTS
    //==============

    // 用户注册新名字事件
    event onNewName
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        bool isNewPlayer,
        uint256 amountPaid,
        uint256 timeStamp
    );

    // 队伍新名字事件
    event onNewTeamName
    (
        uint256 indexed teamID,
        bytes32 indexed teamName,
        uint256 indexed playerID,
        bytes32 playerName,
        uint256 amountPaid,
        uint256 timeStamp
    );
    
    // 购买事件
    event onTx
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 teamID,
        bytes32 teamName,
        uint256 ethIn,
        uint256 keysBought
    );

    // 支付邀请奖励时触发
    event onAffPayout
    (
        uint256 indexed affID,
        address affAddress,
        bytes32 affName,
        uint256 indexed roundID,
        uint256 indexed buyerID,
        uint256 amount,
        uint256 timeStamp
    );

    // 淘汰事件（每回合淘汰一次）
    event onKill
    (
        uint256 deadCount,
        uint256 liveCount,
        uint256 deadKeys
    );

    // 游戏结束事件
    event onEndRound
    (
        uint256 winnerTID,  // winner
        bytes32 winnerTName,
        uint256 playersCount,
        uint256 eth    // eth in pot
    );

    // 提现事件
    event onWithdraw
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 timeStamp
    );

    //==============
    // DATA
    //==============

    // 玩家基本信息
    struct Player {
        address addr;   // 地址 player address
        bytes32 name;   
        uint256 gen;    // 钱包余额：通用
        uint256 aff;    // 钱包余额：邀请奖励
        uint256 laff;   // 最近邀请人（玩家ID）
    }
    
    // 玩家在每局比赛中的信息
    struct PlayerRounds {
        uint256 eth;    // 本局投入的eth成本
        mapping (uint256 => uint256) plyrTmKeys;    // teamid => keys
        bool withdrawn;     // 这轮收益是否已提现
    }

    // 队伍信息
    struct Team {
        uint256 id;     // team id
        bytes32 name;    // team name
        uint256 keys;   // key s in the team
        uint256 eth;   // eth from the team
        uint256 price;    // price of the last key (only for view)
        uint256 playersCount;   // how many team members
        uint256 leaderID;   // leader pID (leader is always the top 1 player in the team)
        address leaderAddr;  // leader address
        bool dead;  // 队伍是否已被淘汰
    }

    // 比赛信息
    struct Round {
        uint256 start;  // 开始时间
        uint256 state;  // 局状态。0: 局未激活，1：局准备，2：杀戮，3：结束（结束后瓜分奖池，相当于ended=true）
        uint256 eth;    // 收到eth总量
        uint256 pot;    // 奖池
        uint256 keys;   // 本轮全部keys
        uint256 team;   // 领先队伍的ID
        uint256 ethPerKey;  // how many eth per key in Winner Team. 只有在比赛结束后才有值。
        uint256 lastKillingTime;   // 上一次淘汰触发时间
        uint256 deadRate;   // 当前淘汰线比率（第一名keys * 淘汰线比率 = 淘汰线）
        uint256 deadKeys;   // 下一次淘汰线（keys低于淘汰线的队伍将被淘汰）
        uint256 liveTeams;  // 活着队伍的数量
        uint256 tID_;    // how many teams in this Round
    }

    // Game
    string constant public name = "War of Eth Official";
    string constant public symbol = "WOE";
    address public owner;
    uint256 constant private roundGap_ = 86400;    // 每两局比赛的间隔（state为0的阶段）：24小时
    uint256 constant private killingGap_ = 86400;   // 淘汰间隔（上一次淘汰时间 + 淘汰间隔 = 下一次淘汰时间）：24小时
    uint256 constant private registrationFee_ = 10 finney;    // 名字注册费

    // Player
    uint256 public pID_;    // 玩家总数
    mapping (address => uint256) public pIDxAddr_;  // (addr => pID) returns player id by address
    mapping (bytes32 => uint256) public pIDxName_;  // (name => pID) returns player id by name
    mapping (uint256 => Player) public plyr_;   // (pID => data) player data
    
    // Round
    uint256 public rID_;    // 当前局ID
    mapping (uint256 => Round) public round_;   // 局ID => 局数据

    // Player Rounds
    mapping (uint256 => mapping (uint256 => PlayerRounds)) public plyrRnds_;  // 玩家ID => 局ID => 玩家在这局中的数据

    // Team
    mapping (uint256 => mapping (uint256 => Team)) public rndTms_;  // 局ID => 队ID => 队伍在这局中的数
    mapping (uint256 => mapping (bytes32 => uint256)) public rndTIDxName_;  // (rID => team name => tID) returns team id by name

    // =============
    // CONSTRUCTOR
    // =============

    constructor() public {
        owner = msg.sender;
    }

    // =============
    // MODIFIERS
    // =============

    // 合约作者才能操作
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // 合约是否已激活
    modifier isActivated() {
        require(activated_ == true, "its not ready yet."); 
        _;
    }
    
    // 只接受用户调用，不接受合约调用
    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }

    // 交易限额
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "no less than 1 Gwei");
        require(_eth <= 100000000000000000000000, "no more than 100000 ether");
        _;
    }

    // =====================
    // PUBLIC INTERACTION
    // =====================

    // 直接打到合约中的钱会由这个方法处理【不推荐，请勿使用】
    // 默认使用上一个邀请人，且资金进入当前领先队伍
    function()
        public
        payable
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
    {
        buy(round_[rID_].team, "");
    }

    // 购买
    // 邀请码只能是用户名，不支持用户ID或Address
    function buy(uint256 _team, bytes32 _affCode)
        public
        payable
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
    {
        // 确保比赛尚未结束
        require(round_[rID_].state < 3, "This round has ended.");

        // 确保比赛已经开始
        if (round_[rID_].state == 0){
            require(now >= round_[rID_].start, "This round hasn&#39;t started yet.");
            round_[rID_].state = 1;
        }

        // 获取玩家ID
        // 如果不存在，会创建新玩家档案
        determinePID(msg.sender);
        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 _tID;

        // 邀请码处理
        // 只能是用户名，不支持用户ID或Address
        uint256 _affID;
        if (_affCode == "" || _affCode == plyr_[_pID].name){
            // 如果没有邀请码，则使用上一个邀请码
            _affID = plyr_[_pID].laff;
        } else {
            // 如果存在邀请码，则获取对应的玩家ID
            _affID = pIDxName_[_affCode];
            
            // 更新玩家的最近邀请人
            if (_affID != plyr_[_pID].laff){
                plyr_[_pID].laff = _affID;
            }
        }

        // 购买处理
        if (round_[rID_].state == 1){
            // Check team id
            _tID = determinTID(_team, _pID);

            // Buy
            buyCore(_pID, _affID, _tID, msg.value);

            // 达到16支队伍就进入淘汰阶段（state: 2）
            if (round_[rID_].tID_ >= 16){
                // 进入淘汰阶段
                round_[rID_].state = 2;

                // 初始化设置
                startKilling();
            }

        } else if (round_[rID_].state == 2){
            // 是否触发结束
            if (round_[rID_].liveTeams == 1){
                // 结束
                endRound();
                
                // 退还资金到钱包账户
                refund(_pID, msg.value);

                return;
            }

            // Check team id
            _tID = determinTID(_team, _pID);

            // Buy
            buyCore(_pID, _affID, _tID, msg.value);

            // Kill if needed
            if (now > round_[rID_].lastKillingTime.add(killingGap_)) {
                kill();
            }
        }
    }

    // 钱包提币
    function withdraw()
        public
        isActivated()
        isHuman()
    {
        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // 确保玩家存在
        require(_pID != 0, "Please join the game first!");

        // 提现金额
        uint256 _eth;

        // 如果存在已经结束的轮次，计算我尚未提现的收益
        if (rID_ > 1){
            for (uint256 i = 1; i < rID_; i++) {
                // 如果尚未提现，则提出金额
                if (plyrRnds_[_pID][i].withdrawn == false){
                    if (plyrRnds_[_pID][i].plyrTmKeys[round_[i].team] != 0) {
                        _eth = _eth.add(round_[i].ethPerKey.mul(plyrRnds_[_pID][i].plyrTmKeys[round_[i].team]) / 1000000000000000000);
                    }
                    plyrRnds_[_pID][i].withdrawn = true;
                }
            }
        }

        _eth = _eth.add(plyr_[_pID].gen).add(plyr_[_pID].aff);

        // 转账
        if (_eth > 0) {
            plyr_[_pID].addr.transfer(_eth);
        }

        // 清空钱包余额
        plyr_[_pID].gen = 0;
        plyr_[_pID].aff = 0;

        // Event 提现
        emit onWithdraw(_pID, plyr_[_pID].addr, plyr_[_pID].name, _eth, now);
    }

    // 注册玩家名字
    function registerNameXID(string _nameString)
        public
        payable
        isHuman()
    {
        // make sure name fees paid
        require (msg.value >= registrationFee_, "You have to pay the name fee.(10 finney)");
        
        // filter name + condition checks
        bytes32 _name = NameFilter.nameFilter(_nameString);
        
        // set up address 
        address _addr = msg.sender;
        
        // set up our tx event data and determine if player is new or not
        // bool _isNewPlayer = determinePID(_addr);
        bool _isNewPlayer = determinePID(_addr);
        
        // fetch player id
        uint256 _pID = pIDxAddr_[_addr];

        // 确保这个名字还没有人用
        require(pIDxName_[_name] == 0, "sorry that names already taken");
        
        // add name to player profile, registry, and name book
        plyr_[_pID].name = _name;
        pIDxName_[_name] = _pID;

        // deposit registration fee
        plyr_[1].gen = (msg.value).add(plyr_[1].gen);
        
        // Event
        emit onNewName(_pID, _addr, _name, _isNewPlayer, msg.value, now);
    }

    // 注册队伍名字
    // 只能由队长设置
    function setTeamName(uint256 _tID, string _nameString)
        public
        payable
        isHuman()
    {
        // 要求team id存在
        require(_tID <= round_[rID_].tID_ && _tID != 0, "There&#39;s no this team.");
        
        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];
        
        // 要求必须是队长
        require(_pID == rndTms_[rID_][_tID].leaderID, "Only team leader can change team name. You can invest more money to be the team leader.");
        
        // 需要注册费
        require (msg.value >= registrationFee_, "You have to pay the name fee.(10 finney)");
        
        // filter name + condition checks
        bytes32 _name = NameFilter.nameFilter(_nameString);

        require(rndTIDxName_[rID_][_name] == 0, "sorry that names already taken");
        
        // add name to team
        rndTms_[rID_][_tID].name = _name;
        rndTIDxName_[rID_][_name] = _tID;

        // deposit registration fee
        plyr_[1].gen = (msg.value).add(plyr_[1].gen);

        // event
        emit onNewTeamName(_tID, _name, _pID, plyr_[_pID].name, msg.value, now);
    }

    //==============
    // GETTERS
    //==============

    // 检查名字可注册
    function checkIfNameValid(string _nameStr)
        public
        view
        returns (bool)
    {
        bytes32 _name = _nameStr.nameFilter();
        if (pIDxName_[_name] == 0)
            return (true);
        else 
            return (false);
    }

    // 查询：距离下一次淘汰的时间
    function getNextKillingAfter()
        public
        view
        returns (uint256)
    {
        require(round_[rID_].state == 2, "Not in killing period.");

        uint256 _tNext = round_[rID_].lastKillingTime.add(killingGap_);
        uint256 _t = _tNext > now ? _tNext.sub(now) : 0;

        return _t;
    }

    // 查询：单个玩家本轮信息 (前端查询用户钱包也是这个方法)
    // 返回：玩家ID，地址，名字，gen，aff，本轮投资额，本轮预计收益，未提现收益
    function getPlayerInfoByAddress(address _addr)
        public 
        view 
        returns(uint256, address, bytes32, uint256, uint256, uint256, uint256, uint256)
    {
        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];

        return (
            _pID,
            _addr,
            plyr_[_pID].name,
            plyr_[_pID].gen,
            plyr_[_pID].aff,
            plyrRnds_[_pID][rID_].eth,
            getProfit(_pID),
            getPreviousProfit(_pID)
        );
    }

    // 查询: 玩家在某轮对某队的投资（_roundID = 0 表示当前轮）
    // 返回 keys
    function getPlayerRoundTeamBought(uint256 _pID, uint256 _roundID, uint256 _tID)
        public
        view
        returns (uint256)
    {
        uint256 _rID = _roundID == 0 ? rID_ : _roundID;
        return plyrRnds_[_pID][_rID].plyrTmKeys[_tID];
    }

    // 查询: 玩家在某轮的全部投资（_roundID = 0 表示当前轮）
    // 返回 keysList数组 (keysList[i]表示用户在i+1队的份额)
    function getPlayerRoundBought(uint256 _pID, uint256 _roundID)
        public
        view
        returns (uint256[])
    {
        uint256 _rID = _roundID == 0 ? rID_ : _roundID;

        // 该轮队伍总数
        uint256 _tCount = round_[_rID].tID_;

        // 玩家在各队的keys
        uint256[] memory keysList = new uint256[](_tCount);

        // 生成数组
        for (uint i = 0; i < _tCount; i++) {
            keysList[i] = plyrRnds_[_pID][_rID].plyrTmKeys[i+1];
        }

        return keysList;
    }

    // 查询：玩家在各轮的成绩（包含本赛季，但是收益为0）
    // 返回 {ethList, winList}  (ethList[i]表示第i+1个赛季的投资)
    function getPlayerRounds(uint256 _pID)
        public
        view
        returns (uint256[], uint256[])
    {
        uint256[] memory _ethList = new uint256[](rID_);
        uint256[] memory _winList = new uint256[](rID_);
        for (uint i=0; i < rID_; i++){
            _ethList[i] = plyrRnds_[_pID][i+1].eth;
            _winList[i] = plyrRnds_[_pID][i+1].plyrTmKeys[round_[i+1].team].mul(round_[i+1].ethPerKey) / 1000000000000000000;
        }

        return (
            _ethList,
            _winList
        );
    }

    // 查询：上一局信息
    // 返回：局ID，状态，奖池金额，获胜队伍ID，队伍名字，队伍人数，总队伍数
    // 如果不存在上一局，会返回一堆0
    function getLastRoundInfo()
        public
        view
        returns (uint256, uint256, uint256, uint256, bytes32, uint256, uint256)
    {
        // last round id
        uint256 _rID = rID_.sub(1);

        // last winner
        uint256 _tID = round_[_rID].team;

        return (
            _rID,
            round_[_rID].state,
            round_[_rID].pot,
            _tID,
            rndTms_[_rID][_tID].name,
            rndTms_[_rID][_tID].playersCount,
            round_[_rID].tID_
        );
    }

    // 查询：本局比赛信息
    function getCurrentRoundInfo()
        public
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        return (
            rID_,
            round_[rID_].state,
            round_[rID_].eth,
            round_[rID_].pot,
            round_[rID_].keys,
            round_[rID_].team,
            round_[rID_].ethPerKey,
            round_[rID_].lastKillingTime,
            killingGap_,
            round_[rID_].deadRate,
            round_[rID_].deadKeys,
            round_[rID_].liveTeams,
            round_[rID_].tID_,
            round_[rID_].start
        );
    }

    // 查询：某支队伍信息
    // 返回：基本信息，队伍成员，及其投资金额
    function getTeamInfoByID(uint256 _tID) 
        public
        view
        returns (uint256, bytes32, uint256, uint256, uint256, uint256, bool)
    {
        require(_tID <= round_[rID_].tID_, "There&#39;s no this team.");
        
        return (
            rndTms_[rID_][_tID].id,
            rndTms_[rID_][_tID].name,
            rndTms_[rID_][_tID].keys,
            rndTms_[rID_][_tID].eth,
            rndTms_[rID_][_tID].price,
            rndTms_[rID_][_tID].leaderID,
            rndTms_[rID_][_tID].dead
        );
    }

    // 查询：所有队伍的信息
    // 返回：id[], name[], keys[], eth[], price[], playersCount[], dead[]
    function getTeamsInfo()
        public
        view
        returns (uint256[], bytes32[], uint256[], uint256[], uint256[], uint256[], bool[])
    {
        uint256 _tID = round_[rID_].tID_;

        // Lists of Team Info
        uint256[] memory _idList = new uint256[](_tID);
        bytes32[] memory _nameList = new bytes32[](_tID);
        uint256[] memory _keysList = new uint256[](_tID);
        uint256[] memory _ethList = new uint256[](_tID);
        uint256[] memory _priceList = new uint256[](_tID);
        uint256[] memory _membersList = new uint256[](_tID);
        bool[] memory _deadList = new bool[](_tID);

        // Data
        for (uint i = 0; i < _tID; i++) {
            _idList[i] = rndTms_[rID_][i+1].id;
            _nameList[i] = rndTms_[rID_][i+1].name;
            _keysList[i] = rndTms_[rID_][i+1].keys;
            _ethList[i] = rndTms_[rID_][i+1].eth;
            _priceList[i] = rndTms_[rID_][i+1].price;
            _membersList[i] = rndTms_[rID_][i+1].playersCount;
            _deadList[i] = rndTms_[rID_][i+1].dead;
        }

        return (
            _idList,
            _nameList,
            _keysList,
            _ethList,
            _priceList,
            _membersList,
            _deadList
        );
    }

    // 获取每个队伍中的队长信息
    // 返回：leaderID[], leaderName[], leaderAddr[]
    function getTeamLeaders()
        public
        view
        returns (uint256[], uint256[], bytes32[], address[])
    {
        uint256 _tID = round_[rID_].tID_;

        // Teams&#39; leaders info
        uint256[] memory _idList = new uint256[](_tID);
        uint256[] memory _leaderIDList = new uint256[](_tID);
        bytes32[] memory _leaderNameList = new bytes32[](_tID);
        address[] memory _leaderAddrList = new address[](_tID);

        // Data
        for (uint i = 0; i < _tID; i++) {
            _idList[i] = rndTms_[rID_][i+1].id;
            _leaderIDList[i] = rndTms_[rID_][i+1].leaderID;
            _leaderNameList[i] = plyr_[_leaderIDList[i]].name;
            _leaderAddrList[i] = rndTms_[rID_][i+1].leaderAddr;
        }

        return (
            _idList,
            _leaderIDList,
            _leaderNameList,
            _leaderAddrList
        );
    }

    // 查询：预测本局的收益（假定目前领先的队伍赢）
    // 返回：eth
    function getProfit(uint256 _pID)
        public
        view
        returns (uint256)
    {
        // 领先队伍ID
        uint256 _tID = round_[rID_].team;

        // 如果用户不持有领先队伍股份，则返回0
        if (plyrRnds_[_pID][rID_].plyrTmKeys[_tID] == 0){
            return 0;
        }

        // 我投资获胜的队伍Keys
        uint256 _keys = plyrRnds_[_pID][rID_].plyrTmKeys[_tID];
        
        // 计算每把Key的价值
        uint256 _ethPerKey = round_[rID_].pot.mul(1000000000000000000) / rndTms_[rID_][_tID].keys;
        
        // 我的Keys对应的总价值
        uint256 _value = _keys.mul(_ethPerKey) / 1000000000000000000;

        return _value;
    }

    // 查询：此前轮尚未提现的收益
    function getPreviousProfit(uint256 _pID)
        public
        view
        returns (uint256)
    {
        uint256 _eth;

        if (rID_ > 1){
            // 计算我已结束的每轮中，尚未提现的收益
            for (uint256 i = 1; i < rID_; i++) {
                if (plyrRnds_[_pID][i].withdrawn == false){
                    if (plyrRnds_[_pID][i].plyrTmKeys[round_[i].team] != 0) {
                        _eth = _eth.add(round_[i].ethPerKey.mul(plyrRnds_[_pID][i].plyrTmKeys[round_[i].team]) / 1000000000000000000);
                    }
                }
            }
        } else {
            // 如果还没有已结束的轮次，则返回0
            _eth = 0;
        }

        // 返回
        return _eth;
    }

    // 下一个完整Key的价格
    function getNextKeyPrice(uint256 _tID)
        public 
        view 
        returns(uint256)
    {  
        require(_tID <= round_[rID_].tID_ && _tID != 0, "No this team.");

        return ( (rndTms_[rID_][_tID].keys.add(1000000000000000000)).ethRec(1000000000000000000) );
    }

    // 购买某队X数量Keys，需要多少Eth？
    function getEthFromKeys(uint256 _tID, uint256 _keys)
        public
        view
        returns(uint256)
    {
        if (_tID <= round_[rID_].tID_ && _tID != 0){
            // 如果_tID存在，则正常计算
            return ((rndTms_[rID_][_tID].keys.add(_keys)).ethRec(_keys));
        } else {
            // 如果_tID不存在，则认为是新队伍
            return ((uint256(0).add(_keys)).ethRec(_keys));
        }
    }

    // X数量Eth，可以买到某队多少keys？
    function getKeysFromEth(uint256 _tID, uint256 _eth)
        public
        view
        returns (uint256)
    {
        if (_tID <= round_[rID_].tID_ && _tID != 0){
            // 如果_tID存在，则正常计算
            return (rndTms_[rID_][_tID].eth).keysRec(_eth);
        } else {
            // 如果_tID不存在，则认为是新队伍
            return (uint256(0).keysRec(_eth));
        }
    }

    // ==========================
    //   PRIVATE: CORE GAME LOGIC
    // ==========================

    // 核心购买方法
    function buyCore(uint256 _pID, uint256 _affID, uint256 _tID, uint256 _eth)
        private
    {
        uint256 _keys = (rndTms_[rID_][_tID].eth).keysRec(_eth);

        // 更新Player、Team、Round数据
        // player
        if (plyrRnds_[_pID][rID_].plyrTmKeys[_tID] == 0){
            rndTms_[rID_][_tID].playersCount++;
        }
        plyrRnds_[_pID][rID_].plyrTmKeys[_tID] = _keys.add(plyrRnds_[_pID][rID_].plyrTmKeys[_tID]);
        plyrRnds_[_pID][rID_].eth = _eth.add(plyrRnds_[_pID][rID_].eth);

        // Team
        rndTms_[rID_][_tID].keys = _keys.add(rndTms_[rID_][_tID].keys);
        rndTms_[rID_][_tID].eth = _eth.add(rndTms_[rID_][_tID].eth);
        rndTms_[rID_][_tID].price = _eth.mul(1000000000000000000) / _keys;
        uint256 _teamLeaderID = rndTms_[rID_][_tID].leaderID;
        // refresh team leader
        if (plyrRnds_[_pID][rID_].plyrTmKeys[_tID] > plyrRnds_[_teamLeaderID][rID_].plyrTmKeys[_tID]){
            rndTms_[rID_][_tID].leaderID = _pID;
            rndTms_[rID_][_tID].leaderAddr = msg.sender;
        }

        // Round
        round_[rID_].keys = _keys.add(round_[rID_].keys);
        round_[rID_].eth = _eth.add(round_[rID_].eth);
        // refresh round leader
        if (rndTms_[rID_][_tID].keys > rndTms_[rID_][round_[rID_].team].keys){
            round_[rID_].team = _tID;
        }

        // 资金分配
        distribute(rID_, _pID, _eth, _affID);

        // Event
        emit onTx(_pID, msg.sender, plyr_[_pID].name, _tID, rndTms_[rID_][_tID].name, _eth, _keys);
    }

    // 资金分配
    function distribute(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID)
        private
    {
        // [1] com - 3%
        uint256 _com = (_eth.mul(3)) / 100;

        // pay community reward
        plyr_[1].gen = _com.add(plyr_[1].gen);

        // [2] aff - 10%
        uint256 _aff = _eth / 10;

        if (_affID != _pID && plyr_[_affID].name != "") {
            // pay aff
            plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
            
            // Event 邀请奖励
            emit onAffPayout(_affID, plyr_[_affID].addr, plyr_[_affID].name, _rID, _pID, _aff, now);
        } else {
            // 如果没有邀请人，则这部分资金并入最终奖池
            // 它并不会影响玩家买到的Keys数量，只会增加最终奖池的金额
            _aff = 0;
        }

        // [3] pot - 87%
        uint256 _pot = _eth.sub(_aff).sub(_com);

        // 更新本局奖池
        round_[_rID].pot = _pot.add(round_[_rID].pot);
    }

    // 结束流程（只能执行一次）
    function endRound()
        private
    {
        require(round_[rID_].state < 3, "Round only end once.");
        
        // 本轮状态更新
        round_[rID_].state = 3;

        // 奖池金额
        uint256 _pot = round_[rID_].pot;

        // Devide Round Pot
        // [1] winner 77%
        uint256 _win = (_pot.mul(77))/100;

        // [2] com 3%
        uint256 _com = (_pot.mul(3))/100;

        // [3] next round 20%
        uint256 _res = (_pot.sub(_win)).sub(_com);

        // 获胜队伍
        uint256 _tID = round_[rID_].team;
        // 计算ethPerKey (每个完整的key对应多少个wei, A Full Key = 10**18 keys)
        uint256 _epk = (_win.mul(1000000000000000000)) / (rndTms_[rID_][_tID].keys);

        // 考虑dust
        uint256 _dust = _win.sub((_epk.mul(rndTms_[rID_][_tID].keys)) / 1000000000000000000);
        if (_dust > 0) {
            _win = _win.sub(_dust);
            _res = _res.add(_dust);
        }

        // pay winner team
        round_[rID_].ethPerKey = _epk;

        // pay community reward
        plyr_[1].gen = _com.add(plyr_[1].gen);

        // Event
        emit onEndRound(_tID, rndTms_[rID_][_tID].name, rndTms_[rID_][_tID].playersCount, _pot);

        // 进入下一局
        rID_++;
        round_[rID_].pot = _res;
        round_[rID_].start = now + roundGap_;
    }
    
    // 退款到钱包账户
    function refund(uint256 _pID, uint256 _value)
        private
    {
        plyr_[_pID].gen = _value.add(plyr_[_pID].gen);
    }

    // 创建队伍
    // 返回 队伍ID
    function createTeam(uint256 _pID, uint256 _eth)
        private
        returns (uint256)
    {
        // 队伍总数不能多于99支
        require(round_[rID_].tID_ < 99, "No more than 99 teams.");

        // 创建队伍至少需要投资1eth
        require(_eth >= 1000000000000000000, "You need at least 1 eth to create a team, though creating a new team is free.");

        // 本局队伍数和存活队伍数增加
        round_[rID_].tID_++;
        round_[rID_].liveTeams++;
        
        // 新队伍ID
        uint256 _tID = round_[rID_].tID_;
        
        // 新队伍数据
        rndTms_[rID_][_tID].id = _tID;
        rndTms_[rID_][_tID].leaderID = _pID;
        rndTms_[rID_][_tID].leaderAddr = plyr_[_pID].addr;
        rndTms_[rID_][_tID].dead = false;

        return _tID;
    }

    // 初始化各项杀戮参数
    function startKilling()
        private
    {   
        // 初始回合的基本参数
        round_[rID_].lastKillingTime = now;
        round_[rID_].deadRate = 10;     // 百分比，按照 deadRate / 100 来使用
        round_[rID_].deadKeys = (rndTms_[rID_][round_[rID_].team].keys.mul(round_[rID_].deadRate)) / 100;
    }

    // 杀戮淘汰
    function kill()
        private
    {
        // 本回合死亡队伍数
        uint256 _dead = 0;

        // 少于淘汰线的队伍淘汰
        for (uint256 i = 1; i <= round_[rID_].tID_; i++) {
            if (rndTms_[rID_][i].keys < round_[rID_].deadKeys && rndTms_[rID_][i].dead == false){
                rndTms_[rID_][i].dead = true;
                round_[rID_].liveTeams--;
                _dead++;
            }
        }

        round_[rID_].lastKillingTime = now;

        // 如果只剩一支队伍，则启动结束程序
        if (round_[rID_].liveTeams == 1 && round_[rID_].state == 2) {
            endRound();
            return;
        }

        // 更新淘汰比率（如果参数修改了，要注意此处判断条件）
        if (round_[rID_].deadRate < 90) {
            round_[rID_].deadRate = round_[rID_].deadRate + 10;
        }

        // 更新下一回合淘汰线
        round_[rID_].deadKeys = ((rndTms_[rID_][round_[rID_].team].keys).mul(round_[rID_].deadRate)) / 100;

        // event
        emit onKill(_dead, round_[rID_].liveTeams, round_[rID_].deadKeys);
    }

    // 通过地址查询玩家ID，如果没有，就创建新玩家
    // 返回：是否为新玩家
    function determinePID(address _addr)
        private
        returns (bool)
    {
        if (pIDxAddr_[_addr] == 0)
        {
            pID_++;
            pIDxAddr_[_addr] = pID_;
            plyr_[pID_].addr = _addr;
            
            return (true);  // 新玩家
        } else {
            return (false);
        }
    }

    // 队伍编号检查，返回编号（仅在当前局使用）
    function determinTID(uint256 _team, uint256 _pID)
        private
        returns (uint256)
    {
        // 确保队伍尚未淘汰
        require(rndTms_[rID_][_team].dead == false, "You can not buy a dead team!");
        
        if (_team <= round_[rID_].tID_ && _team > 0) {
            // 如果队伍已存在，则直接返回
            return _team;
        } else {
            // 如果队伍不存在，则创建新队伍
            return createTeam(_pID, msg.value);
        }
    }

    //==============
    // SECURITY
    //============== 

    // 部署完合约第一轮游戏需要我来激活整个游戏
    bool public activated_ = false;
    function activate()
        public
        onlyOwner()
    {   
        // can only be ran once
        require(activated_ == false, "it is already activated");
        
        // activate the contract 
        activated_ = true;

        // the first player
        plyr_[1].addr = owner;
        plyr_[1].name = "joker";
        pIDxAddr_[owner] = 1;
        pIDxName_["joker"] = 1;
        pID_ = 1;
        
        // 激活第一局.
        rID_ = 1;
        round_[1].start = now;
        round_[1].state = 1;
    }

}   // main contract ends here


// Keys价格相关计算
// 【新算法】keys价格是原来的1000倍
library WoeKeysCalc {
    using SafeMath for *;

    // 根据现有ETH，计算新入X个ETH能购买的Keys数量
    function keysRec(uint256 _curEth, uint256 _newEth)
        internal
        pure
        returns (uint256)
    {
        return(keys((_curEth).add(_newEth)).sub(keys(_curEth)));
    }
    
    // 根据当前Keys数量，计算卖出X数量的keys值多少ETH
    function ethRec(uint256 _curKeys, uint256 _sellKeys)
        internal
        pure
        returns (uint256)
    {
        return((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
    }

    // 根据池中ETH数量计算对应的Keys数量
    function keys(uint256 _eth) 
        internal
        pure
        returns(uint256)
    {
        return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000000);
    }
    
    // 根据Keys数量，计算池中ETH的数量
    function eth(uint256 _keys) 
        internal
        pure
        returns(uint256)  
    {
        return ((78125000000000).mul(_keys.sq()).add(((149999843750000).mul(_keys.mul(1000000000000000000000))) / (2))) / ((1000000000000000000).sq());
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