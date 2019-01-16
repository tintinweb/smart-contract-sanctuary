pragma solidity ^0.4.24;


// 名称检验
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

// 队伍数据库
library F3Ddatasets {
    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr;         // 胜利者地址
        bytes32 winnerName;         // 赢家姓名
        uint256 amountWon;          // 金额赢了
        uint256 newPot;             // 数量在新池里
        uint256 P3DAmount;          // 数量分配给p3d
        uint256 genAmount;          // 数量分配给gen
        uint256 potAmount;          // 添加到池中的数量
    }
    struct Player {
        address addr;               // 玩家地址
        bytes32 name;               // 名称
        uint256 names;              // 名称列表
        uint256 win;                // 赢得金库
        uint256 gen;                // 分红保险库
        uint256 aff;                // 推广保险库
        uint256 lrnd;               // 上一轮比赛
        uint256 laff;               // 使用的最后一个会员ID
    }
    struct PlayerRounds {
        uint256 eth;                // 玩家本回合增加的eth
        uint256 keys;               // 钥匙数
        uint256 mask;               // 玩家钱包
        uint256 ico;                // ICO阶段投资
    }
    struct Round {
        uint256 plyr;               // 领导者的pID
        uint256 team;               // 团队领导的tID
        uint256 end;                // 时间结束/结束
        bool ended;                 // 已经运行了回合函数
        uint256 strt;               // 时间开始了
        uint256 keys;               // 钥匙数量
        uint256 eth;                // 总的eth in
        uint256 pot;                // 奖池（在回合期间）/最终金额支付给获胜者（在回合结束后）
        uint256 mask;               // 全局钱包
        uint256 ico;                // 在ICO阶段发送的总eth
        uint256 icoGen;             // ICO期间gen的总eth
        uint256 icoAvg;             // ICO阶段的平均关键价格
    }
    struct TeamFee {
        uint256 gen;                // 支付给本轮钥匙持有者的分红百分比
        uint256 p3d;                // 支付给p3d持有者的分红百分比
    }
    struct PotSplit {
        uint256 gen;                // 支付给本轮钥匙持有者的底池百分比
        uint256 p3d;                // 支付给p3d持有者的底池百分比
    }
}

// 安全数学库
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

    function div(uint256 a, uint256 b)
    internal
    pure
    returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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


// TinyF3D游戏
contract TinyF3D {

    using SafeMath for *;
    using NameFilter for string;

    string constant public name = "Tiny Fomo3D long";           // 游戏名称
    string constant public symbol = "T3D";                      // 游戏符号

    // 游戏数据
    address public owner;                                       // 合约管理者
    address public devs;                                        // 开发团队
    address public otherF3D_;                                   // 副奖池

    bool public activated_ = false;                             // 合同部署标志

    uint256 private rndExtra_ = 0;                              // 第一个ICO的时间
    uint256 private rndGap_ = 0;                                // ICO阶段的时间,现为马上结束
    uint256 constant private rndInit_ = 24 * 60 * 60 seconds;                // 回合倒计时开始
    uint256 constant private rndInc_ = 30 seconds;              // 每一把钥匙增加时间
    uint256 constant private rndMax_ = 24 * 60 * 60 seconds;                // 最大倒计时时间

    uint256 public airDropPot_;                                 // 空头罐
    uint256 public airDropTracker_ = 0;                         // 空投计数
    uint256 public rID_;                                        // 回合轮数

    uint256 public registrationFee_ = 10 finney;                // 注册价格

    // 玩家数据
    uint256 public pID_;                                        // 玩家总数
    mapping(address => uint256) public pIDxAddr_;               //（addr => pID）按地址返回玩家ID
    mapping(bytes32 => uint256) public pIDxName_;               //（name => pID）按名称返回玩家ID
    mapping(uint256 => F3Ddatasets.Player) public plyr_;        //（pID => data）玩家数据
    mapping(uint256 => mapping(uint256 => F3Ddatasets.PlayerRounds)) public plyrRnds_;    //（pID => rID => data）玩家ID和轮次ID的玩家轮数据
    mapping(uint256 => mapping(bytes32 => bool)) public plyrNames_;       //（pID => name => bool）玩家拥有的名字列表。
                                                                          //（用于这样您可以在您拥有的任何名称中更改您的显示名称）
    mapping(uint256 => mapping(uint256 => bytes32)) public plyrNameList_; //（pID => nameNum => name）玩家拥有的名称列表

    // 回合数据
    mapping(uint256 => F3Ddatasets.Round) public round_;        //（rID => data）回合数据
    mapping(uint256 => mapping(uint256 => uint256)) public rndTmEth_;    //（rID => tID => data）每个团队中的eth，按轮次ID和团队ID

    // 团队数据
    mapping(uint256 => F3Ddatasets.TeamFee) public fees_;       //（团队=>费用）按团队分配费用
    mapping(uint256 => F3Ddatasets.PotSplit) public potSplit_;  //（团队=>费用）按团队分配分配

    // 每当玩家注册一个名字时就会被触发
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

    // 购买并分红
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

    // 收到副奖池存款
    event onPotSwapDeposit
    (
        uint256 roundID,
        uint256 amountAddedToPot
    );

    // 购买结束事件
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

    //每当联盟会员付款时都会被解雇
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

    // 撤回收入事件
    event onWithdraw
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 timeStamp
    );

    // 撤回收入分发事件
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

    // 只有当玩家在回合结束后尝试重新加载时才会触发
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

    // 确保在合约激活前不能使用
    modifier isActivated() {
        require(activated_ == true, "its not ready yet.  check ?eta in discord");
        _;
    }

    // 禁止其他合约调用
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    // 保证调用者是开发者
    modifier onlyDevs()
    {
        require(msg.sender == devs, "msg sender is not a dev");
        _;
    }

    // dev设置传入交易金额的边界
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;
    }

    // 合同部署后激活一次
    function activate()
    public
    onlyDevs
    {
        //只能运行一次
        require(activated_ == false, "TinyF3d already activated");

        //激活合同
        activated_ = true;

        //让我们开始第一轮
        rID_ = 1;
        round_[1].strt = now + rndExtra_ - rndGap_;
        round_[1].end = now + rndInit_ + rndExtra_;
    }

    // 合约部署初始数据设置
    constructor()
    public
    {
        owner = msg.sender;
        devs = msg.sender;
        otherF3D_ = msg.sender;

        // 团队分配结构
        // 0 =鲸鱼
        // 1 =熊
        // 2 = 蛇
        // 3 =公牛

        // 团队分红
        //（F3D，P3D）+（奖池，推荐，社区）
        //fees_[0] = F3Ddatasets.TeamFee(30, 6);          // 50％为奖池，10％推广，2％为公司，1％为副奖池，1％为空投罐
        fees_[1] = F3Ddatasets.TeamFee(43, 0);          // 43％为奖池，10％推广，2％为公司，1％为副奖池，1％为空投罐
        //fees_[2] = F3Ddatasets.TeamFee(56, 10);         // 20％为奖池，10％推广，2％为公司，1％为副奖池，1％为空投罐
        //fees_[3] = F3Ddatasets.TeamFee(43, 8);          // 35％为奖池，10％推广，2％为公司，1％为副奖池，1％为空投罐

        // 结束奖池分配
        //（F3D, P3D）+（获胜者，下一轮，公司）
        //potSplit_[0] = F3Ddatasets.PotSplit(15, 10);    // 获胜者48％，下一轮25％，com 2％
        potSplit_[1] = F3Ddatasets.PotSplit(0, 0);     // 获胜者48％，下一轮25％，com 2％
        //potSplit_[2] = F3Ddatasets.PotSplit(20, 20);    // 获胜者48％，下一轮10％，com 2％
        //potSplit_[3] = F3Ddatasets.PotSplit(30, 10);    // 获胜者48％，下一轮10％，com 2％
        determinePID(owner);
    }

    // 匿名函数,用来紧急购买
    function()
    isActivated()
    isHuman()
    isWithinLimits(msg.value)
    public
    payable
    {
        // 设置交易事件数据并确定玩家是否是新玩家
        F3Ddatasets.EventReturns memory _eventData_ = determinePlayer(_eventData_);

        // 获取玩家ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // 买核心
        buyCore(_pID, plyr_[_pID].laff, 2, _eventData_);
    }

    // 存在或注册新的pID。当玩家可能是新手时使用此功能
    function determinePlayer(F3Ddatasets.EventReturns memory _eventData_)
    private
    returns (F3Ddatasets.EventReturns)
    {
        uint256 _pID = pIDxAddr_[msg.sender];

        // 如果玩家是新手
        if (_pID == 0)
        {
            // 从玩家姓名合同中获取他们的玩家ID，姓名和最后一个身份证
            determinePID(msg.sender);
            _pID = pIDxAddr_[msg.sender];
            bytes32 _name = plyr_[_pID].name;
            uint256 _laff = plyr_[_pID].laff;

            // 设置玩家账号
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

            // 将新玩家设置为true
            _eventData_.compressedData = _eventData_.compressedData + 1;
        }
        return (_eventData_);
    }

    // 确定玩家ID
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

 
    // 通过地址购买
    function buyXaddr(address _affCode)
    isActivated()
    isHuman()
    isWithinLimits(msg.value)
    public
    payable
    {
        // 设置交易事件数据,确定玩家是否是新玩家
        F3Ddatasets.EventReturns memory _eventData_ = determinePlayer(_eventData_);

        // 获取玩家ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // 如果没有推广人并且推广人不是自己
        uint256 _affID;
        if (_affCode == address(0) || _affCode == msg.sender)
        {
            // 使用最后存储的推广人代码
            _affID = plyr_[_pID].laff;
        } else {
            // 获取推广ID
            _affID = pIDxAddr_[_affCode];

            // 如果推广ID与先前存储的不同
            if (_affID != plyr_[_pID].laff)
            {
                // 更新最后一个推广人代码
                plyr_[_pID].laff = _affID;
            }
        }

        // 确认选择了有效的团队
        uint256 _team;
        _team = 2;

        // 买核心
        buyCore(_pID, _affID, _team, _eventData_);
    }

    
    
    // 购买
    function buyCore(uint256 _pID, uint256 _affID, uint256 _team, F3Ddatasets.EventReturns memory _eventData_)
    private
    {
        // 设置本地rID
        uint256 _rID = rID_;

        // 当前时间
        uint256 _now = now;

        // 如果回合进行中
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {
            // 尝试购买
            core(_rID, _pID, msg.value, _affID, _team, _eventData_);
        } else {
            // 如果round不活跃

            // 检查是否回合已经结束
            if (_now > round_[_rID].end && round_[_rID].ended == false)
            {
                // 结束回合（奖池分红）并开始新回合
                round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);

                // 构建事件数据
                _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
                _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

                // 发起购买事件
                emit onBuyAndDistribute
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

            //把eth放在球员保险库里
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }

    // 重新购买
    function reLoadCore(uint256 _pID, uint256 _affID, uint256 _team, uint256 _eth, F3Ddatasets.EventReturns memory _eventData_)
    private
    {
        // 设置本地rID
        uint256 _rID = rID_;

        // 获取时间
        uint256 _now = now;

        // 回合进行中
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {
            // 从所有保险库中获取收益并将未使用的保险库返还给gen保险库
            plyr_[_pID].gen = withdrawEarnings(_pID).sub(_eth);

            // 购买
            core(_rID, _pID, _eth, _affID, _team, _eventData_);
        } else if (_now > round_[_rID].end && round_[_rID].ended == false) {
            // 回合结束,奖池分红,并开始新回合
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

            // 构建事件数据
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

            // 发送购买和分发事件
            emit onReLoadAndDistribute
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

    // 如果管理员开始新一轮,移动玩家没有保存的钱包收入到保险箱
    function managePlayer(uint256 _pID, F3Ddatasets.EventReturns memory _eventData_)
    private
    returns (F3Ddatasets.EventReturns)
    {
        // 如果玩家玩过上一轮，则移动他们的收入到保险箱。
        if (plyr_[_pID].lrnd != 0)
            updateGenVault(_pID, plyr_[_pID].lrnd);

        // 更新玩家的最后一轮比赛
        plyr_[_pID].lrnd = rID_;

        // 将参与的回合bool设置为true
        _eventData_.compressedData = _eventData_.compressedData + 10;

        return (_eventData_);
    }

    // 计算没有归入钱包的收入（只计算，不更新钱包）
    // 返回wei格式的收入
    function calcUnMaskedEarnings(uint256 _pID, uint256 _rIDlast)
    private
    view
    returns (uint256)
    {
        return ((((round_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1000000000000000000)).sub(plyrRnds_[_pID][_rIDlast].mask));
    }

    // 将收入移至收入保险箱
    function updateGenVault(uint256 _pID, uint256 _rIDlast)
    private
    {
        uint256 _earnings = calcUnMaskedEarnings(_pID, _rIDlast);
        if (_earnings > 0)
        {
            // 放入分红库
            plyr_[_pID].gen = _earnings.add(plyr_[_pID].gen);
            // 更新钱包并将收入归0
            plyrRnds_[_pID][_rIDlast].mask = _earnings.add(plyrRnds_[_pID][_rIDlast].mask);
        }
    }

    // 根据购买的全部钥匙数量更新回合计时器
    function updateTimer(uint256 _keys, uint256 _rID)
    private
    {
        // 当前时间
        uint256 _now = now;

        // 根据购买的钥匙数计算时间
        uint256 _newTime;
        if (_now > round_[_rID].end && round_[_rID].plyr == 0)
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(_now);
        else
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(round_[_rID].end);

        // 与最长限制比较并设置新的结束时间
        if (_newTime < (rndMax_).add(_now))
            round_[_rID].end = _newTime;
        else
            round_[_rID].end = rndMax_.add(_now);
    }

    // 检查空投
    function airdrop()
    private
    view
    returns (bool)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(

                (block.timestamp).add
                (block.difficulty).add
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
                (block.gaslimit).add
                ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
                (block.number)

            )));
        if ((seed - ((seed / 1000) * 1000)) < airDropTracker_)
            return (true);
        else
            return (false);
    }

    // 购买核心
    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, F3Ddatasets.EventReturns memory _eventData_)
    private
    {
        // 如果玩家是新手
        if (plyrRnds_[_pID][_rID].keys == 0)
            _eventData_ = managePlayer(_pID, _eventData_);

        // 早期的道德限制器 <100eth ... >=1eth 早期奖池小于100eth，一个玩家一局限制购买最多1eth
        if (round_[_rID].eth < 100000000000000000000 && plyrRnds_[_pID][_rID].eth.add(_eth) > 1000000000000000000)
        {
            uint256 _availableLimit = (1000000000000000000).sub(plyrRnds_[_pID][_rID].eth); // 1eth
            uint256 _refund = _eth.sub(_availableLimit);
            plyr_[_pID].gen = plyr_[_pID].gen.add(_refund);
            _eth = _availableLimit;
        }

        // 如果eth大于最小购买eth数量
        if (_eth > 1000000000) //0.0000001eth
        {

            // 计算可购买钥匙数量
            uint256 _keys = keysRec(round_[_rID].eth,_eth);

            // 如果至少买一把钥匙19位
            if (_keys >= 1000000000000000000)
            {
                updateTimer(_keys, _rID);

                // 设置新的领先者
                if (round_[_rID].plyr != _pID)
                    round_[_rID].plyr = _pID;
                if (round_[_rID].team != _team)
                    round_[_rID].team = _team;

                // 将新的领先者布尔设置为true
                _eventData_.compressedData = _eventData_.compressedData + 100;
            }
 
            // 更新玩家数据
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);

            // 更新回合数据
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = _eth.add(round_[_rID].eth);
            rndTmEth_[_rID][_team] = _eth.add(rndTmEth_[_rID][_team]);

            // eth分红
            _eventData_ = distributeExternal(_rID, _pID, _eth, _affID, _team, _eventData_);
            _eventData_ = distributeInternal(_rID, _pID, _eth, _team, _keys, _eventData_);

            // 调用结束交易函数来触发结束交易事件。
            endTx(_pID, _team, _eth, _keys, _eventData_);
        }
    }

    // 返回玩家金库
    function getPlayerVaults(uint256 _pID)
    public
    view
    returns (uint256, uint256, uint256)
    {
        // 设置本地rID
        uint256 _rID = rID_;

        // 如果回合结束尚未开始（因此合同没有分配奖金）
        if (now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
            // 如果玩家是赢家
            if (round_[_rID].plyr == _pID)
            {
                return
                (
                (plyr_[_pID].win).add(((round_[_rID].pot).mul(100)) / 100),
                (plyr_[_pID].gen).add(getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)),
                plyr_[_pID].aff
                );
            } else {
                // 如果玩家不是赢家
                return
                (
                plyr_[_pID].win,
                (plyr_[_pID].gen).add(getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)),
                plyr_[_pID].aff
                );
            }
        } else {
            // 如果回合仍然在进行或者回合结束又已经运行
            return
            (
            plyr_[_pID].win,
            (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),
            plyr_[_pID].aff
            );
        }
    }

    // 计算金库金额帮助函数
    function getPlayerVaultsHelper(uint256 _pID, uint256 _rID)
    private
    view
    returns (uint256)
    {
        return (((((round_[_rID].mask).add(((((round_[_rID].pot).mul(potSplit_[round_[_rID].team].gen)) / 100).mul(1000000000000000000)) / (round_[_rID].keys))).mul(plyrRnds_[_pID][_rID].keys)) / 1000000000000000000));
    }

    // 压缩数据并触发购买更新交易事件
    function endTx(uint256 _pID, uint256 _team, uint256 _eth, uint256 _keys, F3Ddatasets.EventReturns memory _eventData_)
    private
    {
        _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000) + (_team * 100000000000000000000000000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + _pID + (rID_ * 10000000000000000000000000000000000000000000000000000);

        emit onEndTx
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

    // 外部分红
    function distributeExternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, F3Ddatasets.EventReturns memory _eventData_)
    private
    returns (F3Ddatasets.EventReturns)
    {
        
        

        // 向FoMo3D支付5％的费用
        uint256 _long = _eth * 465 / 10000;
        otherF3D_.transfer(_long);

        // 将推广费用分配给会员
        uint256 _aff1 = _eth * 2 / 100;
        uint256 _aff2 = _eth * 5 / 100;

        // 决定如何处理推广费用
        // 不能是自己，并且必须注册名称
        // 如果没有就归P3D
        if (_affID != _pID && _affID != 0 ) {
            plyr_[_affID].aff = _aff1.add(plyr_[_affID].aff);
            emit onAffiliatePayout(_affID, plyr_[_affID].addr, plyr_[_affID].name, _rID, _pID, _aff1, now);
        } else {
            plyr_[1].aff = _aff1.add(plyr_[1].aff);
            emit onAffiliatePayout(1, plyr_[1].addr, plyr_[1].name, _rID, _pID, _aff1, now);
        }
        
        uint256 _affID2 = plyr_[_affID].laff;
        if (_affID2 != _pID && _affID2 != 0 ) {
            plyr_[_affID2].aff = _aff2.add(plyr_[_affID2].aff);
            emit onAffiliatePayout(_affID2, plyr_[_affID2].addr, plyr_[_affID2].name, _rID, _pID, _aff2, now);
        } else {
            plyr_[1].aff = _aff2.add(plyr_[1].aff);
            emit onAffiliatePayout(1, plyr_[1].addr, plyr_[1].name, _rID, _pID, _aff2, now);
        }

        return (_eventData_);
    }

    // 内部分红
    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _team, uint256 _keys, F3Ddatasets.EventReturns memory _eventData_)
    private
    returns (F3Ddatasets.EventReturns)
    {
        // 计算分红份额
        uint256 _gen = (_eth.mul(465)) / 10000;

        // 将1％投入空投罐
        //uint256 _air = (_eth / 100);
        //airDropPot_ = airDropPot_.add(_air);

        // 更新eth balance（eth = eth  - （com share + pot swap share + aff share + p3d share + airdrop pot share））
        uint256 _long = _eth * 465 / 10000;
        uint256 a = ((_eth.mul(7)) / 100).add(_long);
        _eth = _eth.sub(a);

        // 计算的奖池
        uint256 _pot = _eth.sub(_gen);//42%奖   分红份额43% 3%+7%

        // 分发分红
        uint256 _dust = updateMasks(_rID, _pID, _gen, _keys);
        if (_dust > 0)
            _gen = _gen.sub(_dust);

        // 添加eth到奖池
        round_[_rID].pot = _pot.add(_dust).add(round_[_rID].pot);

        // 设置事件数据
        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _pot;

        return (_eventData_);
    }

  

    // 购买钥匙时更新回合和玩家钱包
    function updateMasks(uint256 _rID, uint256 _pID, uint256 _gen, uint256 _keys)
    private
    returns (uint256)
    {

        // 基于此次购买的每个钥匙和回合分红利润:(剩余进入奖池）
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        round_[_rID].mask = _ppt.add(round_[_rID].mask);

        // 计算自己的收入（基于刚刚买的钥匙数量）并更新玩家钱包
        uint256 _pearn = (_ppt.mul(_keys)) / (1000000000000000000);
        plyrRnds_[_pID][_rID].mask = (((round_[_rID].mask.mul(_keys)) / (1000000000000000000)).sub(_pearn)).add(plyrRnds_[_pID][_rID].mask);

        //计算并返回灰尘
        return (_gen.sub((_ppt.mul(round_[_rID].keys)) / (1000000000000000000)));
    }

    // 结束了本回合,支付赢家和平分奖池
    function endRound(F3Ddatasets.EventReturns memory _eventData_)
    private
    returns (F3Ddatasets.EventReturns)
    {
        // 获取一个rID
        uint256 _rID = rID_;

        // 获取获胜玩家和队伍
        uint256 _winPID = round_[_rID].plyr;
        uint256 _winTID = 2;

        // 获取奖池
        uint256 _pot = round_[_rID].pot;

        // 计算获胜玩家份额，社区奖励，公司份额，
        // P3D分享，以及为下一个底池保留的金额
        uint256 _win = (_pot.mul(100)) / 100;


        // 支付我们的赢家
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);

        // P3D奖励
        

        // 将gen部分分发给密钥持有者
       // round_[_rID].mask = _ppt.add(round_[_rID].mask);

        // 将P3D的份额发送给divies
        

        // 准备事件
        _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * 100000000000000000000000000) + (_winTID * 100000000000000000);
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.winnerName = plyr_[_winPID].name;
        _eventData_.amountWon = _win;
        _eventData_.genAmount = 0;
        _eventData_.P3DAmount = 0;
        _eventData_.newPot = 0;

        // 新一轮开始
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_).add(rndGap_);
        round_[_rID].pot = 0;

        return (_eventData_);
    }

    // 通过地址获取玩家信息
    function getPlayerInfoByAddress(address _addr)
    public
    view
    returns (uint256, bytes32, uint256, uint256, uint256, uint256, uint256)
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
        _pID, //0
        plyr_[_pID].name, //1
        plyrRnds_[_pID][_rID].keys, //2
        plyr_[_pID].win, //3
        (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)), //4
        plyr_[_pID].aff, //5
        plyrRnds_[_pID][_rID].eth           //6
        );
    }

    // 回合数据
    function getCurrentRoundInfo()
    public
    view
    returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, bytes32, uint256, uint256, uint256, uint256, uint256)
    {
        // 设置本地rID
        uint256 _rID = rID_;

        return
        (
        round_[_rID].ico, //0
        _rID, //1
        round_[_rID].keys, //2
        round_[_rID].end, //3
        round_[_rID].strt, //4
        round_[_rID].pot, //5
        (round_[_rID].team + (round_[_rID].plyr * 10)), //6
        plyr_[round_[_rID].plyr].addr, //7
        plyr_[round_[_rID].plyr].name, //8
        rndTmEth_[_rID][0], //9
        rndTmEth_[_rID][1], //10
        rndTmEth_[_rID][2], //11
        rndTmEth_[_rID][3], //12
        airDropTracker_ + (airDropPot_ * 1000)              //13
        );
    }

    // 撤回所有收入
    function withdraw()
    isActivated()
    isHuman()
    public
    {
        // 设置本地rID
        uint256 _rID = rID_;

        // 获取时间
        uint256 _now = now;

        // 获取玩家ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // 临时变量
        uint256 _eth;

        // 检查回合是否已经结束，还没有人绕过回合结束
        if (_now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
            // 设置交易事件
            F3Ddatasets.EventReturns memory _eventData_;

            // 结束回合（奖池分红）
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

            // 得到他的收入
            _eth = withdrawEarnings(_pID);

            // 支付玩家
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

            // 构建事件数据
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

            // 撤回分发事件
            emit onWithdrawAndDistribute
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
        } else {
            // 在任何其他情况下
            // 得到他的收入
            _eth = withdrawEarnings(_pID);

            // 支付玩家
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

            // 撤回事件
            emit onWithdraw(_pID, msg.sender, plyr_[_pID].name, _eth, _now);
        }
    }

    // 将未显示的收入和保险库收入加起来返回,并将它们置为0
    function withdrawEarnings(uint256 _pID)
    private
    returns (uint256)
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

        return (_earnings);
    }
    
 
    // 计算给定eth可购买的钥匙数量
    function calcKeysReceived(uint256 _rID, uint256 _eth)
    public
    view
    returns (uint256)
    {
        // 获取时间
        uint256 _now = now;

        // 回合进行中
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) {
            return keysRec(round_[_rID].eth + _eth,_eth);
        } else {
            // 如果结束,返回新一轮的数量
            return keys(_eth);
        }
    }

    // 返回购买指定数量钥匙需要的eth
    function iWantXKeys(uint256 _keys)
    public
    view
    returns (uint256)
    {
        // 设置本地rID
        uint256 _rID = rID_;

        // 获取时间
        uint256 _now = now;

        // 在回合进行中
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ethRec(round_[_rID].keys + _keys,_keys);
        else // 如果结束,返回新一轮的价格
            return eth(_keys);
    }    


    // 计算以太币能够购买的钥匙数量
    function keysRec(uint256 _curEth, uint256 _newEth)
    internal
    pure
    returns (uint256)
    {
        return(keys((_curEth).add(_newEth)).sub(keys(_curEth)));
    }

    function keys(uint256 _eth)
    internal
    pure
    returns(uint256)
    {
        return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000);
    }

    function ethRec(uint256 _curKeys, uint256 _sellKeys)
    internal
    pure
    returns (uint256)
    {
        return((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
    }

    function eth(uint256 _keys)
    internal
    pure
    returns(uint256)
    {
        return ((78125000).mul(_keys.sq()).add(((149999843750000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
    }
}