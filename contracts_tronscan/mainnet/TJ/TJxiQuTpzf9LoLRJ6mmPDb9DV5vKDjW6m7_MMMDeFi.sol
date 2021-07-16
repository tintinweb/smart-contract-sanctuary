//SourceUnit: MMMDeFi.sol

pragma solidity ^0.5.12;

library TransferHelper {
    address constant USDTAddr = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C;
    function safeTransfer(address token, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        if (token == USDTAddr) {
            return success;
        }
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface Token {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Ticket {
    using SafeMath for uint256;
    // 购买门票:用户地址,系统周期,门票数量
    event IssueTicket(address userAddr, uint256 period, uint256 ticketAmount);
    // 转让门票:发起方地址,接收方地址,系统周期,门票数量
    event TransferTicket(address userAddr, address targetAddr, uint256 period, uint256 ticketAmount);
    // 扣除门票:用户地址,系统期数,门票数量
    event BurnTicket(address userAddr, uint256 period, uint256 ticketAmount);

    uint256 public period = 1; // 系统期数
    uint256 public totalSupply; // 门票总额
    uint256 public totalTotalSupply; // 门票总发行量
    uint256 public totalTotalDestroy; // 门票总消耗量
    mapping(address => uint256) public balanceOf; // 用户地址 -> 门票持仓
    mapping(address => mapping(uint256 => uint256)) public destroyOf; // 用户地址 -> 系统期数 -> 门票消耗

    // 转让门票
    function transfer(address _from, address _to, uint256 _value) internal {
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit TransferTicket(_from, _to, period, _value);
    }

    // 购买门票
    function issue(address _to, uint256 _value) internal {
        // 门票累计发行量
        totalTotalSupply = totalTotalSupply.add(_value);
        totalSupply = totalSupply.add(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit IssueTicket(_to, period, _value);
    }

    // 扣除门票
    function burn(address _from, uint256 _value) internal {
        // 门票余额不足
        require(balanceOf[_from] >= _value, "Insufficient ticket balance");
        // 门票累计消耗
        totalTotalDestroy = totalTotalDestroy.add(_value);
        totalSupply = totalSupply.sub(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        destroyOf[_from][period] = destroyOf[_from][period].add(_value);
        emit BurnTicket(_from, period, _value);
    }
}

contract Utils {
    // 两数取最小值
    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        return a < b ? a : b;
    }

    // 两数取最大值
    function max(uint256 a, uint256 b) internal pure returns(uint256) {
        return a > b ? a : b;
    }
}

contract MMMDeFi is Ticket, Utils {
    using TransferHelper for address;
    // 初始化设置超级管理员:超级管理员地址
    event SetOwner(address owner);
    // 注册:执行操作的用户地址,系统周期,注册地址,上级地址
    event Register(address sender, uint256 period, address userAddr, address refAddr);
    // 会员每期保险补偿结算: 用户地址,结算补偿的系统周期,当前的系统周期,金额
    event ChagngeRecover(address userAddr,uint256 prePeriod, uint256 period, uint256 amount);
    // 保险补偿待支付队列:用户地址,系统周期,类型(1进队/2出队),金额
    event ChangeRecoverQueue(address userAddr, uint256 period, uint256 action, uint256 amount);
    // 会员职位变化:用户地址,系统期数,4正常晋升/5冻结用户,职位等级
    event ChangeLevel(address userAddr, uint256 period, uint256 action, uint256 level);
    // 会员可取奖金变动:奖金类型(同UserPoolStruct中定义),用户地址,系统周期,增加(1)/减少(2),变化金额,变化后的总额
    event ChangePool(string rewardType, address userAddr, uint256 period, uint256 action, uint256 amount, uint256 totalAmount);
    // 会员捐助订单冻结天数变动:用户地址;系统周期;用户订单索引;已解冻天数
    event ChangeDonate(address userAddr, uint256 period, uint256 index, uint256 updateDay);
    // 系统奖池变化:奖池类型(同JackpotPoolStruct中定义/互助奖池:helpPool),系统周期,增加(1)/减少(2),变化金额,变化后的总额
    event ChangeSysPool(string poolType, uint256 period, uint256 action, uint256 amount, uint256 totalAmount);
    // 捐助订单:用户地址;系统周期;捐助金额;订单日率;冻结周期;用户订单索引;系统订单索引
    event FreezeOrder(address userAddr, uint256 period, uint256 amount, uint256 rate, uint256 freezeDay, uint256 orderId, uint256 sysOrderIndex);
    // 解冻订单:用户地址;系统周期;用户订单索引;关联订单索引;金额;
    event UnfreezeOrder(address userAddr, uint256 period, uint256 orderId, uint256 useOrderId, uint256 unfreezeAmount);
    // 发起提案:发起者地址,提案编号,投票有效时长,投票权限,提案地址,类型(1暂停地址/2升级合约/>=3冻结用户时长)
    event StartProposal(address userAddr, uint256 proposalIndex, uint256 time, uint256 auth, address proposalAddress, uint256 proposalType);
    // 提案投票:用户地址,提案编号,投票结果(通过/不通过)
    event VoteProposal(address userAddr, uint256 proposalIndex, bool voteStatus);
    // 提案状态更改:用户地址,提案编号,状态(true通过/false不通过)
    event ChangeProposalStatus(address userAddr, uint256 proposalIndex, uint256 result);
    // 权限变更:操作地址;目标地址;动作(1分配权限/2收回权限);分类(1管理权/2执行权);权限编号
    event ChangeAuth(address userAddr, address targetAddr, uint256 action, uint256 authType, uint256 authNum);
    /**
    * 通用布尔值更改:开关类型;系统周期;用户地址;状态(true/false)
    * 开关类型:任务基金开关(enableTask)/待支付任务基金自动划转开关(enableTaskAutoTran)
    * 竞赛基金开关(enableContest)/竞猜基金开关(enableGuess)/暂停合约状态(isPause)
    * 重启过渡期(allowRestart)
    */
    event ChangeSwitch(string changeType, uint256 period, address userAddr, bool status);
    /**
    * 通用金额参数更改:参数类型;系统周期;用户地址;修改值;
    * 参数类型:taskLimitAmount待支付任务基金余额上限/taskAutoTranAmount待支付任务基金自动划转金额
     */
    event ChangeAmount(string changeType, uint256 period, address userAddr, uint256 amount);
    /**
    * 通用数字更改:参数类型;用户地址;修改值;
    * 参数类型:restartTime重启冻结过渡期/period周期
     */
    event ChangeUnit(string changeType, uint256 period, address userAddr, uint256 value);
    // 授权合约调用团队结构合约:用户地址,合约地址,状态(true授权/false收回权限)
    event ChangeLicenseAddr(address userAddr, address contractAddr, bool status);
    // 固化全球分红奖:系统周期,本轮轮次,本轮开始时间(时间戳/秒),本轮结束时间(时间戳/秒),本轮全球分红总人数,本轮每人可获取的奖励,本轮全球分红总金额
    event CalcSysDividend(uint256 period, uint256 dividendRound, uint256 startTime,
        uint256 endTime, uint256 neilNum, uint256 amount, uint256 totalAmount);
    // 冻结或者解冻用户:操作地址,用户地址,系统周期,分类(1冻结/2解冻),冻结时长
    event ChangeFreezeUser(address sender, address userAddr, uint256 period, uint256 action, uint256 endTime);
    // 参与竞猜:用户地址,系统周期,竞猜轮次,竞猜人数值,竞猜金额值
    event DoGuess(address userAddr, uint256 period, uint256 round, uint256 count, uint256 amount);
    // 员工工资:用户地址,系统周期,工资轮次,动作(1增加/2减少),金额
    event ChangeSalary(address userAddr, uint256 period, uint256 round, uint256 action, uint256 amount);
    // 提交竞赛中奖记录:用户地址,系统周期,竞赛类型,业绩,获奖时间,获奖等级,获奖金额
    event CalcContest(address userAddr, uint256 period, uint256 contestType, uint256 value, uint256 time, uint256 level, uint256 amount);
    // 提交竞猜中奖记录:用户地址,系统周期,竞猜类型,竞猜内容,获奖轮次,获奖等级,获奖金额
    event CalcGuess(address userAddr, uint256 period, uint256 guessType, uint256 value, uint256 round, uint256 level, uint256 amount);
    // 提交任务链接:用户地址,系统周期,任务链接
    event DoTask(address userAddr, uint256 period, string link);
    // 提交任务获奖记录:用户地址,系统周期,任务类型,任务编码,防伪码,获奖金额
    event CalcTask(address userAddr, uint256 period, uint256 taskType, bytes32 taskId, bytes32 security, uint256 amount);
    // 运维生态转账记录: 系统周期,转账金额,转账目标地址
    event TransferEcologyOpsAmount(uint256 period, uint256 amount, address ecologyOpsAddr);
    // 修改运维生态私人地址:操作地址,系统周期,运维生态基金地址
    event ChangeEcologyOpsAddr(address sender, uint256 period, address ecologyOpsAddr);

    Token public token; // 代币合约
    uint256 constant private depth = 80; // 系统最大层级, 用于限制最大层级
    uint256 public depthLevel = depth; // 更新上级等级的最大层级
    uint256 constant private dayToSecond = 1 days; // 1天对应的秒数

    uint256 public restartTime = 3 * dayToSecond; // 重启冻结过渡期(72小时)
    uint256 public restartStartTime = 0; // 重启开始时间
    bool public allowRestart = false; // 是否允许重启

    address public ecologyOpsAddr; // 运维生态基金地址

    mapping(uint256 => uint256) public eachStartTime; // 系统期数 -> 开始时间

    modifier isRestart() {
        if (allowRestart) {
            // 系统处于重启冻结过渡期中
            require(restartStartTime.add(restartTime) <= now, "Now is the transition period before the restart");
            // 重置重启标志
            allowRestart = false;
            // 重启自增系统期数
            period = period.add(1);
            // 更新系统本期开始时间
            eachStartTime[period] = now;
            // 重置系统降级倍数
            sysTmpRate = 0;
            sysRateTime = 0;
            emit ChangeUnit("period", period, msg.sender, period);
            emit ChangeSwitch("allowRestart", period, msg.sender, allowRestart);
        }
        _;
    }

    // 构造函数, 仅合约创建时执行:Token地址;超级管理员地址;生态运维奖地址
    constructor(Token _tokenAddr, address _owner, address _ecologyOpsAddr) public {
        // 设置代币合约地址
        token = Token(_tokenAddr);
        // 创建创世用户
        register(address(0), address(0));
        // 超级管理员授权
        owner = _owner;
        // 运维生态基金地址
        ecologyOpsAddr = _ecologyOpsAddr;
        // 本期系统开始时间
        eachStartTime[period] = now;
        emit SetOwner(owner);
    }

    uint256 public userNum = 0; // 当前用户数, 用于检查用户是否注册和统计用户量
    mapping(address => uint256) public userCode; // 用户地址 -> 用户编号
    // 用户邀请关系定义
    struct UserStruct {
        address userAddr; // 用户地址
        address refAddr; // 上级地址
        address[] refs; // 上级地址集合, 例: A -> B -> C -> D, 当前用户处于C, 即存储 [A, B]
    }
    mapping(address => UserStruct) public users; // 用户地址 -> 用户邀请关系
    // 用户期数信息定义
    struct UserInfoStruct {
        uint256 currAmount; // 当前最大捐助金额索引
        uint256 nextAmount; // 下一阶梯最大捐助金额索引
        uint256 nextAmountTime; // 下一阶梯最大捐助金额晋级时间
        uint256 level; // 职位
        uint256 childNum; // 直推激活下级总数
        uint256 orderNum; // 团队首次激活总数(含自身)
        uint256 activeNum1; // 第一条线最大激活数
        uint256 activeNum2; // 第二条线最大激活数
        bool active; // 是否首次激活
    }
    mapping(address => mapping(uint256 => UserInfoStruct)) public userInfo; // 用户地址 -> 系统期数 -> 用户期数信息

    // 注册-⽤户给⾃⼰直接下级绑定注册⽤户或者给自己注册直接下级
    function childRegister(address userAddr, address refAddr) public checkPauseUpgrade {
        // 非下级用户或非自己
        require(users[refAddr].refAddr == msg.sender || refAddr == msg.sender, "Non subordinate or non self");
        _userRegister(userAddr, refAddr);
    }

    // 用户注册, 检查权限
    function userRegister(address refAddr) public checkPauseUpgrade {
        _userRegister(msg.sender, refAddr);
    }

    // 用户注册
    function _userRegister(address userAddr, address refAddr) private {
        // 检查用户地址是否已注册
        require(userCode[userAddr] == 0, "The address already exists");
        // 检查用户地址是否可注册（第一批用户和普通邀请用户）
        require(checkWorkAuth(userAddr, 1001) || refAddr != address(0), "Registration unauthorized ");
        // 检查上级地址已激活
        require(refAddr == address(0) || (refAddr != address(0) && userInfo[refAddr][period].active == true), "Parent not activated");
        register(userAddr, refAddr);
    }

    mapping(address => bool) public licenseContract; // 已授权的合约地址

    // 检查是否为授权合约调用
    modifier onlyContract() {
        // 仅授权合约可调用注册接口
        require(licenseContract[msg.sender], "It's not a contract address");
        _;
    }

    // 仅用于合约升级后, 授权合约调用
    function registerByContract(address userAddr, address refAddr) public onlyContract {
        // 检查旧合约是升级状态
        require(isUpgrade, "Not upgraded");
        // 检查用户地址是否已注册
        require(userCode[userAddr] == 0, "The address already exists");
        // 检查上级用户地址是否存在
        require(userCode[refAddr] != 0, "The superior user does not exist");
        _createUser(userAddr, refAddr);
    }

    function _createUser(address userAddr, address refAddr) private {
        // 系统用户数自增
        userNum = userNum.add(1);
        userCode[userAddr] = userNum;
        // 获取上级地址集合
        address[] memory refs = getRefs(refAddr);

        // 创建用户邀请关系
        UserStruct memory userStruct;
        userStruct = UserStruct({
            userAddr: userAddr,
            refAddr: refAddr,
            refs: refs
        });
        users[userAddr] = userStruct;
    }

    // 用户注册
    function register(address userAddr, address refAddr) private {
        _createUser(userAddr, refAddr);

        // 创建用户期数信息
        UserInfoStruct memory userInfoStruct;
        userInfoStruct = UserInfoStruct({
            currAmount: 0,
            nextAmount: 0,
            nextAmountTime: now,
            level: 1,
            childNum: 0,
            orderNum: 0,
            activeNum1: 0,
            activeNum2: 0,
            active: false
        });
        userInfo[userAddr][period] = userInfoStruct;
        emit Register(msg.sender, period, userAddr, refAddr);
    }

    // 获取用户上级地址集合, 仅存储距用户地址最近的深度个数地址
    function getRefs(address refAddr) public view returns (address[] memory) {
        address[] memory refs;
        // 用户上级集合: address(0)
        if (refAddr == address(0)) {
            refs = new address[](1);
            refs[0] = address(0);
            return refs;
        }
        // 层数不足最大深度的上级集合: 1-len + 上级地址
        uint256 len = users[refAddr].refs.length;
        uint256 start = 0;
        uint256 end = len;
        uint256 maxLen = len.add(1);
        // 层数达到最大深度的上级集合: 1-99 + 上级地址
        if (len >= depth) {
            start = 1;
            end = len.sub(1);
            maxLen = len;
        }
        refs = new address[](maxLen);
        uint256 x = 0;
        for (uint256 i = start; i < len; i = i.add(1)) {
            refs[x] = users[refAddr].refs[i];
            x = x.add(1);
        }
        refs[end] = refAddr;
        return refs;
    }

    // 系统奖池(重启后仍然保留)
    uint256 public sysRecoverPool; // 补偿基金奖池

    // 奖池基金-重启后仍然保留
    uint256 public contestPool; // 每日竞赛奖
    uint256 public guessPool; // 每日竞猜奖
    uint256 public taskPool; // 任务基金
    uint256 public taskPayPool; // 任务待支付奖池

    // 奖池基金定义
    struct JackpotPoolStruct {
        uint256 dividendPool; // 全球分红奖
        uint256 superPool; // 终极竞赛大奖
    }
    mapping(uint256 => JackpotPoolStruct) public jackpots; // 系统期数 -> 奖池基金
    mapping(uint256 => uint256) public helpPool; // 系统期数 -> 互助奖池

    uint256 private startTime = now; // 系统上线时间
    uint256 constant private decimals = 6; // 系统金额单位, 与USDT保持1:1兑换

    uint256 constant private recoverRate = 50; // 门票-补偿基金50%
    uint256 constant private taskRate = 50; // 门票-任务基金50%
    bool public enableTask = true; // 任务基金开关
    bool public enableTaskAutoTran = true; // 待支付任务基金自动划转开关
    uint256 public taskLimitAmount = 10000 * 10 ** decimals; // 待支付任务基金余额上限
    uint256 public taskAutoTranAmount = 10000 * 10 ** decimals; // 待支付任务基金自动划转金额

    mapping(address => uint256) public neilNormalTime; // 用户地址 -> 晋升全球经理时间, 用于计算是否获得全球分红奖励
    mapping(uint256 => uint256) public neilNum; // 系统周期 -> 全球经理职位总数, 用于投票计算通过率。重启后职位不保留
    mapping(uint256 => uint256) public leaderNum; // 系统周期 -> 领导人职位总数, 用于投票计算通过率。重启后职位不保留
    mapping(uint256 => uint256) public managerNum; // 系统周期 -> 经理职位总数, 用于投票计算通过率。重启后职位不保留

    // 购买门票
    function buyTicket(uint256 _amount) public checkPauseUpgrade {
        address userAddr = msg.sender;
        // 检查该用户是否存在首次激活订单
        require(userInfo[userAddr][period].active == true, "User not activated");
        // 检查购买门票金额是否为1USDT的整数倍
        require(_amount.mod(10 ** decimals) == 0, "Amount must be an integer multiple of 1");
        // 转移USDT资金至本合约
        require(address(token).safeTransferFrom(userAddr, address(this), _amount), "Transfer failed");

        // 分发门票金额
        // 将门票金额分配到50%任务基金
        uint256 taskAmount = _amount.mul(taskRate).div(100);
        // 检查任务基金是否关闭
        if (!enableTask) {
            // 若任务基金关闭, 划转到互助奖池
            updateHelpPool(taskAmount, true);
        } else {
            // 若任务基金开启, 划转到任务奖池
            taskPool = taskPool.add(taskAmount);
            emit ChangeSysPool("taskPool", period, 1, taskAmount, taskPool);
            tranWaitPayTask();
        }
        // 将门票金额分配到50%保险补偿基金
        uint256 recoverAmount = _amount.mul(recoverRate).div(100);
        sysRecoverPool = sysRecoverPool.add(recoverAmount);
        emit ChangeSysPool("sysRecoverPool", period, 1, recoverAmount, sysRecoverPool);

        // 增加用户门票金额
        issue(userAddr, _amount);

        //补偿用户（补偿队列中的用户）
        _recoverQueueUser();
    }

    // 重置系统晋升等级总数
    function _resetAfterLevel(address userAddr) private {
        if(userInfo[userAddr][period].level == 7) {
            // 减少系统领导人总数
            leaderNum[period] = leaderNum[period].sub(1);
        }else if(userInfo[userAddr][period].level == 8) {
            // 减少系统经理人总数
            managerNum[period] = managerNum[period].sub(1);
        }else if(userInfo[userAddr][period].level == 9) {
            // 减少系统经理人总数
            neilNum[period] = neilNum[period].sub(1);
        }
    }

    // 自动划转任务基金至待支付奖池
    function tranWaitPayTask() private {
        // 检查自动划转是否开启、任务基金是否足够支付自动划转金额、任务待支付奖池是否小于自动划转金额
        if (
            enableTaskAutoTran &&
            taskPool >= taskAutoTranAmount &&
            taskPayPool < taskLimitAmount
        ) {
            // 任务基金扣除10000USDT
            taskPool = taskPool.sub(taskAutoTranAmount);
            // 任务待支付奖池增加10000USDT
            taskPayPool = taskPayPool.add(taskAutoTranAmount);
            emit ChangeSysPool("taskPool", period, 2, taskAutoTranAmount, taskPool);
            emit ChangeSysPool("taskPayPool", period, 1, taskAutoTranAmount, taskPayPool);
        }
    }

    // 转让门票
    function tranTicket(address _to, uint256 _value) public checkPauseUpgrade {
        // 检查接收方是否存在首次激活订单
        require(userInfo[_to][period].active == true, "Receiver not activated");
        transfer(msg.sender, _to, _value);
        //补偿用户（补偿队列中的用户）
        _recoverQueueUser();
    }

    uint256 constant private minAmount = 50 * 10 ** decimals; // 最小捐助金额
    uint256[] private amounts = [
        2000 * 10 ** decimals,
        4000 * 10 ** decimals,
        6000 * 10 ** decimals,
        8000 * 10 ** decimals,
        10000 * 10 ** decimals
    ]; // 捐助金额阶梯
    uint256 constant private upgradeAmountTime = 10 * dayToSecond; // 捐助金额晋升间隔时间
    uint256[][] private rates = [[17, 7], [14, 10], [11, 15], [8, 20], [5, 25], [3, 30]]; // 奖金倍数 -> 日率配置

    uint256 public sysRate = 0; // 系统降级倍数
    uint256 public sysCurrRatio = 100; // 当前距离互助奖池最大值的降级比例
    mapping(uint256 => uint256) public maxHelpPool; // 系统周期->互助基金奖池最高位
    uint256 public sysRateTime = 0; // 系统倍率降级或升级的更新时间
    uint256 private sysTmpRate = 0; // 系统临时降级倍数, 未满足缓冲时间
    uint256 private sysTmpTmpRate = 0; // 系统临时降级倍数缓存值,计算sysTmpRate更新时间
    uint256 constant private sysStableTime = 10 * dayToSecond; // 系统倍率降级或升级时, 需缓冲的时间

    uint256 constant private helpRate = 97; // 互助基金比例

    uint256 constant private dividendRate = 5; // 全球分红奖比例
    uint256 constant private contestRate = 3; // 每日竞赛奖比例
    uint256 constant private guessRate = 2; // 每日竞猜奖比例
    uint256 constant private superRate = 5; // 终极竞赛大奖比例
    uint256 constant private ecologyOpsRate = 15; // 生态运维比例

    uint256 constant private ticketRate = 10; // 提取奖金时(除开本金/补偿/员工工资), 需要扣除提现金额的10%门票

    // 订单数据结构定义
    struct OrderStruct {
        uint256 rate; // 订单日率
        uint256 freezeDay; // 冻结期, 单位: 天
        uint256 amount; // 捐款金额
        uint256 createdAt; // 创建时间
        uint256 updateDay; // 已解冻的天数, 单位: 天
        bool isUse; // 是否关联使用过
        bool isExtract; // 标记是否已提取本金, 指定解冻订单需要检查此状态
    }
    mapping(address => mapping(uint256 => OrderStruct[])) public orders; // 用户地址 -> 系统期数 -> 订单详细信息
    // 订单总览数据结构定义
    struct OrderInfoStruct {
        uint256 reward; // 用户本期领取过的收益, 用于计算给用户的补偿金额
        uint256 earn; // 用户解冻奖金合计总额(捐助奖、1-5代推荐奖、6-10代领导奖(已结算过)、无限代经理奖、经理导师奖)
        uint256 fund; // 用户场内本金总额
        uint256 rate; // 用户订单日率
    }
    mapping(address => mapping(uint256 => OrderInfoStruct)) public orderInfo; // 用户地址 -> 系统期数 -> 订单总览数据

    uint256 constant private recommendRate = 10; // 1-5代推荐奖比例

    // 用户奖金定义
    struct UserPoolStruct {
        uint256 donate; // 捐助奖金
        uint256 recommend; // 1-5代推荐奖
        uint256 leader; // 6-10代领导奖
        uint256 manager; // 无限代经理奖
        uint256 mentor; // 经理导师奖
        uint256 contest; // 每日竞赛奖
        uint256 guess; // 每日竞猜奖
        uint256 task; // 任务基金
        uint256 offlineTask; // 离线任务奖
        uint256 superReward; // 终极竞赛大奖
    }
    mapping(address => mapping(uint256 => UserPoolStruct)) public userReward; // 用户地址 -> 系统期数 -> 用户奖金
    // 用户全局奖金定义, 不受期数影响
    mapping(address => uint256) public recoverReward; // 用户地址 -> 用户保险补偿奖金

    bool public enableRef = true; // 是否启用1-5代推荐奖
    bool public enableLeader = true; // 是否启用领导奖、经理奖

    uint256 dividendStartTime = startTime; // 全球分红每轮开始时间, 以24h的步长递增, 开始时间为系统上线时间
    uint256 public dividendRound = 0; // 全球分红轮次

    // 全球分红奖励数据结构定义
    struct DividendInfoStruct {
        uint256 reward; // 本轮每人可获取的奖励
        uint256 num; // 本轮全球分红总人数
        uint256 amount; // 本轮全球分红总金额, 从全球分红奖池扣除
        uint256 endTime; // 本轮全球分红结束时间
    }
    mapping(uint256 => DividendInfoStruct) public dividendInfo; // 每轮全球分红奖励

    uint256 private recoveOrderRate = 10; // 补偿基金比例, 捐助订单金额的10%
    uint256 public currRecoverID = 0; // 补偿队列长度, 编号递增
    uint256 public recoverDoneID = 0; // 已补偿的补偿队列编号, 用于补偿时作为起始位置
    // 补偿队列数据结构定义
    struct RecoverListStruct {
        address userAddr; // 用户地址
        uint256 loss; // 损失金额, 捐助订单金额的10%累加
    }
    mapping (uint256 => RecoverListStruct) public recoverList;
    mapping (address => uint256) public recoverInfo; // 用户地址 -> 亏损金额, 当用户捐助订单时, 亏损金额减少, 可领取金额增加
    mapping (address => uint256) public recoverListInfo; // 用户地址 -> 补偿队列中的总金额，进补偿队列增加，补偿后减少，用户合约升级计算损失

    // 系统订单列表数据结构定义
    struct OrderListStruct {
        address userAddr; // 用户地址
        uint256 amount; // 捐款金额
    }
    mapping(uint256 => OrderListStruct[]) public orderList; // 系统期数 -> 系统订单信息, 每期订单列表, 用于计算终极竞赛大奖

    bool public enableContest = true; // 启用竞赛基金开关
    bool public enableGuess = true; // 启用竞猜基金开关

    // 创建捐助订单
    function freezeOrder(uint256 amount) public isRestart checkPauseUpgrade {
        address sender = msg.sender;
        // 检查用户地址是否已注册
        require(userCode[sender] != 0, "Address not registered");
        // 检查金额是否大于等于最小捐助金额且是最小捐助金额整数倍
        require(amount >= minAmount && amount % minAmount == 0, "Not less than the minimum amount and an integral multiple of the minimum amount");
        // 检查捐助金额是否超出捐助金额阶梯
        uint256 currAmount = userInfo[sender][period].currAmount;
        uint256 nextAmount = userInfo[sender][period].nextAmount;
        uint256 nextAmountTime = userInfo[sender][period].nextAmountTime;
        // 下一阶梯晋升时间 + 晋升间隔时间 <= 当前时间
        bool isUpgradeAmount = nextAmountTime.add(upgradeAmountTime) <= now;
        // 金额小于等于捐助金额阶梯、金额小于等于下一阶梯的金额且满足晋升时间限制
        require(amount <= amounts[currAmount] || (amount <= amounts[nextAmount] && isUpgradeAmount), "Donation amount exceeds the ladder");

        // 转移USDT资金至本合约
        require(address(token).safeTransferFrom(sender, address(this), amount), "Transfer failed");

        // 将捐助订单金额分配给奖池
        distributeAmount(amount);

        // 固化全球分红奖
        calcSysDividend();

        // 捐助金额阶梯晋升
        // 检查是否达到过当前最大捐助金额, 且满足晋升时间限制
        if (currAmount != nextAmount && isUpgradeAmount) {
            userInfo[sender][period].currAmount = userInfo[sender][period].currAmount.add(1);
            currAmount = userInfo[sender][period].currAmount;
        }
        // 检查金额是否达到当前最大捐助金额, 且未更新过下一阶梯, 且下一阶梯小于最大阶梯
        if (amount == amounts[currAmount] && currAmount == nextAmount && currAmount < amounts.length.sub(1)) {
            userInfo[sender][period].nextAmount = userInfo[sender][period].nextAmount.add(1);
            userInfo[sender][period].nextAmountTime = now;
        }
        // 更新用户场内本金总额, 本笔冻结订单金额也需要一起计算日率
        orderInfo[sender][period].fund = orderInfo[sender][period].fund.add(amount);
        // 计算订单倍率
        uint256 rate = calcOrderRate(sender);
        // 更新用户订单日率
        orderInfo[sender][period].rate = rates[rate][0];

        // 创建订单
        OrderStruct memory orderStruct;
        orderStruct = OrderStruct({
            freezeDay: rates[rate][1],
            amount: amount,
            createdAt: now,
            updateDay: 0,
            isUse: false,
            rate: rates[rate][0],
            isExtract: false
        });
        orders[sender][period].push(orderStruct);
        // 创建系统订单
        OrderListStruct memory orderListStruct;
        orderListStruct = OrderListStruct({
            userAddr: sender,
            amount: amount
        });
        orderList[period].push(orderListStruct);

        // 更新上级及以上代数的职位状态数据
        updateRefInfo(sender);

        // 计算1-5代推荐奖
        calcRecommend(sender, amount, rates[rate][1]);

        emit FreezeOrder(sender, period, amount, rates[rate][0], rates[rate][1], getLastID(sender), orderList[period].length.sub(1));
    }

    // 计算订单倍率, 捐助奖, 1-5代推荐奖, 6-10代领导奖(已结算过), 无限代经理奖, 经理导师奖
    function calcOrderRate(address userAddr) public view returns(uint256) {
        OrderInfoStruct memory _orderInfo = orderInfo[userAddr][period];
        if(_orderInfo.fund == 0) {
            return sysRate;
        }
        uint256 rate = _orderInfo.earn.div(_orderInfo.fund).add(sysRate);
        return min(rate, 5);
    }

    // 更新互助基金金额
    function updateHelpPool(uint256 amount, bool isAdd) private {
        if (isAdd) {
            helpPool[period] = helpPool[period].add(amount);
            emit ChangeSysPool("helpPool", period, 1, amount, helpPool[period]);
        } else {
            helpPool[period] = helpPool[period].sub(amount);
            emit ChangeSysPool("helpPool", period, 2, amount, helpPool[period]);
        }
        // 检查是否更新系统日率, 系统日率受互助基金金额和10*24h缓冲期影响
        if (now > sysRateTime.add(sysStableTime) && sysRate != sysTmpRate) {
            sysRate = sysTmpRate;
            if (sysRate == 0) { // 6档
              // 恢复1-5代推荐奖结算
              enableRef = true;
              // 恢复领导奖和经理奖结算
              enableLeader = true;
            }else if(sysRate == 1) { // 5档
              // 恢复1-5代推荐奖结算
              enableRef = true;
              // 停止领导奖和经理奖结算
              enableLeader = false;
            } else if (sysRate == 2) { // 4档
              // 停止1-5代推荐奖结算
              enableRef = false;
              // 停止领导奖和经理奖结算
              enableLeader = false;
            }
        }
        uint256 tmpHelpPool = helpPool[period];
        if(tmpHelpPool > maxHelpPool[period]) {
            maxHelpPool[period] = tmpHelpPool;
        }
        uint256 rate = min(tmpHelpPool.mul(100).div(maxHelpPool[period]), 100);
        // 系统档位升档过程
        if (rate > sysCurrRatio) {
            // 恢复
            if (rate >= 100) {
                // 档级恢复为6档
                sysTmpRate = 0;
            } else if (rate >= 75 && sysRate == 2){
                // 档级恢复为5档
                sysTmpRate = 1;
            }
        } else if (rate < sysCurrRatio) {
            // 系统档位降档过程
            if (rate <= 50) {
                // 档级调整为4档
                sysTmpRate = 2;
            }else if (rate <= 75) {
                // 档级调整为5档
                sysTmpRate = 1;
            }
        }
        sysCurrRatio = rate;
        // 更新日率档位变化时间
        if(sysTmpTmpRate != sysTmpRate) {
            sysRateTime = now;
            sysTmpTmpRate = sysTmpRate;
        }
    }

    // 订单金额分发到各奖池
    function distributeAmount(uint256 amount) private {
        // 分配97%至互助奖池
        uint256 helpAmount = amount.mul(helpRate).div(100);

        // 分配3%至奖池基金
        // 全球分红奖0.5%
        uint256 dividendAmount = amount.mul(dividendRate).div(1000);
        if (neilNum[period] == 0) {
            // 当全球经理人数为0时, 划转到互助奖池
            helpAmount = helpAmount.add(dividendAmount);
        } else {
            // 已有全球经理, 划转到全球分红奖池
            jackpots[period].dividendPool = jackpots[period].dividendPool.add(dividendAmount);
            emit ChangeSysPool("dividendPool", period, 1, dividendAmount, jackpots[period].dividendPool);
        }

        // 每日竞赛奖0.3%
        uint256 contestAmount = amount.mul(contestRate).div(1000);
        if (!enableContest) {
            // 关闭基金, 划转到互助奖池
            helpAmount = helpAmount.add(contestAmount);
        } else {
            // 开启基金, 流入竞赛奖池
            contestPool = contestPool.add(contestAmount);
            emit ChangeSysPool("contestPool", period, 1, contestAmount, contestPool);
        }

        // 每日免费竞猜奖0.2%
        uint256 guessAmount = amount.mul(guessRate).div(1000);
        if (!enableGuess) {
            // 关闭基金, 划转到互助奖池
            helpAmount = helpAmount.add(guessAmount);
        } else {
            // 开启基金, 流入奖池
            guessPool = guessPool.add(guessAmount);
            emit ChangeSysPool("guessPool", period, 1, guessAmount, guessPool);
        }

        // 终极竞赛大奖0.5%
        uint256 superAmount = amount.mul(superRate).div(1000);
        jackpots[period].superPool = jackpots[period].superPool.add(superAmount);
        emit ChangeSysPool("superPool", period, 1, superAmount, jackpots[period].superPool);

        // 转账1.5%到生态运维基金地址
        uint256 ecologyOpsAmount = amount.mul(ecologyOpsRate).div(1000);
        require(address(token).safeTransfer(ecologyOpsAddr, ecologyOpsAmount), "Transfer failed");
        emit TransferEcologyOpsAmount(period, ecologyOpsAmount, ecologyOpsAddr);

        // 更新互助基金
        updateHelpPool(helpAmount, true);
    }

    // 计算用户等级
    function calcLevel(address userAddr) private view returns(uint256) {
        uint256 childNum = userInfo[userAddr][period].childNum;
        uint256 num1 = userInfo[userAddr][period].activeNum1;
        uint256 num2 = userInfo[userAddr][period].activeNum2;
        // 2条线, 每条线各500人, 直推20人
        if (childNum >= 20 && num1 >= 500 && num2 >= 500) {
            return 9; // 全球经理
        }
        // 2条线, 每条线各250人, 直推15人
        if (childNum >= 15 && num1 >= 250 && num2 >= 250) {
            return 8; // 经理人
        }
        // 2条线, 每条线各100人, 直推10人
        if (childNum >= 10 && num1 >= 100 && num2 >= 100) {
            return 7; // 领导人
        }
        // 直推5人
        if (childNum >= 5) {
            return 6; // 5星
        }
        if (childNum >= 4) {
            return 5; // 4星
        }
        if (childNum >= 3) {
            return 4; // 3星
        }
        if (childNum >= 2) {
            return 3; // 2星
        }
        if (childNum >= 1) {
            return 2; // 1星
        }
        return 1;
    }

    // 变更用户等级
    function setLevel(address userAddr) private {
        // 被冻结的用户职位无需变更
        if(now < unfreezeUserTime[period][userAddr]) {
           return;
        }
        uint256 level = calcLevel(userAddr);
        uint256 userLevel = userInfo[userAddr][period].level;
        if (level == 9 && userLevel < 9) {
            // 系统晋升全球经理
            // 全球经理总人数自增
            neilNum[period] = neilNum[period].add(1);
            // 更新用户晋升时间
            neilNormalTime[userAddr] = now;
            // 记录可领取全球分红轮次(可以领取成为全球经理后,下一轮全球经理奖)
            dividendDrawIdx[userAddr] = dividendRound.add(1);
        } else if (level == 8 && userLevel < 8) {
            // 系统晋升经理
            // 经理总人数自增
            managerNum[period] = managerNum[period].add(1);
        } else if (level == 7 && userLevel < 7) {
            // 系统晋升领导人
            // 领导人总人数自增
            leaderNum[period] = leaderNum[period].add(1);
        }
        // 等级相同无需变更
        if (level != userLevel) {
            // 重置晋升后原有等级总数
            _resetAfterLevel(userAddr);
            userInfo[userAddr][period].level = level;
            emit ChangeLevel(userAddr, period, 4, level);
        }
    }

    // 更新所有上级职位状态数据
    function updateRefInfo(address sender) private {
        // 检查是否为首次激活订单
        if (userInfo[sender][period].active == false) {
            // 影响用户自身状态: 首次激活, 激活总数自增, 职位晋升
            // 首次激活状态置为已激活
            userInfo[sender][period].active = true;
            // 用户激活总数自增
            userInfo[sender][period].orderNum = userInfo[sender][period].orderNum.add(1);

            // 影响直接上级地址状态: 直推人数自增
            // 直推人数自增
            address refAddr = users[sender].refAddr;
            if(userInfo[refAddr][period].active) {
                userInfo[refAddr][period].childNum = userInfo[refAddr][period].childNum.add(1);
                // 计算上级用户职位状态
                setLevel(refAddr);
            }

            // 影响上级地址状态: 激活总数自增, 职位晋升, 两条线激活总数更新
            // 更新有限代上级状态
            uint256 len = users[sender].refs.length;
            uint256 maxLen = min(depthLevel, len);
            for (uint256 i = 0; i < maxLen; i = i.add(1)) {
                // 上级地址子项, 从距离最近的地址开始迭代
                address item = users[sender].refs[len.sub(1).sub(i)];
                // 上级激活总数自增
                userInfo[item][period].orderNum = userInfo[item][period].orderNum.add(1);
                // 为上级地址的邀请人, 计算两条线激活总数
                address itemRef = users[item].refAddr;
                if (itemRef != address(0) && userInfo[item][period].active && userInfo[itemRef][period].active) {
                    // 每条线的激活数可以理解为, 直推下级的团队激活总数(含自身)
                    uint256 orderNum = userInfo[item][period].orderNum;
                    if (orderNum > userInfo[itemRef][period].activeNum1) {
                        userInfo[itemRef][period].activeNum1 = orderNum;
                        // 计算上级用户职位状态
                        setLevel(itemRef);
                    } else if (orderNum > userInfo[itemRef][period].activeNum2) {
                        userInfo[itemRef][period].activeNum2 = orderNum;
                        // 计算上级用户职位状态
                        setLevel(itemRef);
                    }
                }
            }
        }
    }

    // 扣除门票
    function burnTicket(address userAddr, uint256 amount, uint256 reward) private {
        // 扣除提现金额的10%门票
        uint256 ticket = amount.mul(ticketRate).div(100);
        // 扣除门票
        burn(userAddr, ticket);
        // 增加用户本期领取过的收益
        if(reward > 0) {
            orderInfo[userAddr][period].reward = orderInfo[userAddr][period].reward.add(reward);
        }
    }

    // 发送奖励
    function sendReward(address userAddr, uint256 amount, uint256 reward) private {
        // 扣除门票
        burnTicket(userAddr, amount, reward);
        // 发放奖励
        require(address(token).safeTransfer(userAddr, amount), "Transfer failed");
    }

    // 获取用户本期订单总数
    function getUserOrderNum(address userAddr) public view returns(uint256) {
        return orders[userAddr][period].length;
    }

    // 获取用户本期最新一笔订单ID
    function getLastID(address userAddr) private view returns(uint256) {
        uint256 _orderNum = getUserOrderNum(userAddr);
        if(_orderNum == 0) {
            return 0;
        }
        return _orderNum.sub(1);
    }

    // 检查是否存在冻结中的订单, 仅需要检查最后一笔订单是否处于冻结中
    function checkFreezeOrder(address userAddr) public view returns(bool) {
        uint256 lastID = getLastID(userAddr);
        uint256 _orderNum = getUserOrderNum(userAddr);
        // 异常情况不存订单（订单总数=0，最后一单ID=0），返回false
        if(_orderNum != lastID) {
            // 订单未处于冻结期内
            return !checkOrderUnFreeze(userAddr, lastID);
        }
        return false;
    }

    // 计算烧伤, 捐款本金取用户与上级间的小值, 上级捐款本金取其最后一个冻结订单的本金金额; 日率取用户和上级间的小值
    function calcBurn(address refAddr, uint256 amount, uint256 rate) public view returns(uint256, uint256) {
        // 检查是否存在冻结中的订单, 上代用户没有冻结订单，捐款本金取值 0
        bool freeze = checkFreezeOrder(refAddr);
        if (!freeze) {
            return (0, 0);
        }
        uint256 len = getUserOrderNum(refAddr);
        uint256 lastAmount = orders[refAddr][period][len.sub(1)].amount;
        uint256 lastRate = orderInfo[refAddr][period].rate;
        return (min(amount, lastAmount), min(rate, lastRate));
    }

    // 计算1-5代推荐奖
    function calcRecommend(address userAddr, uint256 amount, uint256 freezeDay) private {
        // 未启用1-5代推荐奖
        if (!enableRef) {
            return;
        }
        uint256 refLen = users[userAddr].refs.length;
        uint256 rate = orderInfo[userAddr][period].rate;
        uint256 len = min(refLen, 5);
        for (uint256 i = 0; i < len; i = i.add(1)) {
            address item = users[userAddr].refs[refLen.sub(1).sub(i)];
            uint256 level = userInfo[item][period].level;
            // A -> B -> C -> D -> E -> F
            // 满足E为1星参与者就能拿一代的推荐奖
            if (
                (i == 0 && level >= 2) ||
                (i == 1 && level >= 3) ||
                (i == 2 && level >= 4) ||
                (i == 3 && level >= 5) ||
                (i == 4 && level >= 6)
            ) {
                // 计算烧伤
                uint256 amountTmp = 0;
                uint256 rateTmp = 0;
                (amountTmp, rateTmp) = calcBurn(item, amount, rate);
                // 1-5代推荐奖: 订单金额 * 冻结期 * 日率 * 10%
                // 捐助奖
                uint256 _donate = amountTmp.mul(freezeDay).mul(rateTmp).div(1000);
                uint256 reward = _donate.mul(recommendRate).div(100);
                if(reward > 0) {
                    userReward[item][period].recommend = userReward[item][period].recommend.add(reward);
                    emit ChangePool("recommend", item, period, 1, reward, userReward[item][period].recommend);
                }
            }
        }
    }

    // 固化全球分红奖
    function calcSysDividend() public checkPauseUpgrade {
        // 检查当前时间是否满足一轮的时间要求
        // 1. 跨越多个24h, 空白24h前端补齐
        // 2. 若第1个24h产生的全球分红没有触发固化, 第2个24h晋升全球经理可平分第1个24h的分红
        uint256 amount = jackpots[period].dividendPool;
        if(now >= dividendStartTime.add(dayToSecond)) {
            // 上轮结束时间 = (当前时间 - (当前时间 - 每轮开始时间) % 24h)
            uint256 endTime = now.sub(now.sub(dividendStartTime).mod(dayToSecond));
            if (neilNum[period] > 0 && amount > 0) {
                // 按照轮次计算
                dividendRound = dividendRound.add(1);
                // 创建本轮全球分红奖励记录
                DividendInfoStruct memory dividendInfoStruct;
                // 本轮每人可获取的奖励
                uint256 reward = amount.div(neilNum[period]);
                dividendInfoStruct = DividendInfoStruct({
                    reward: reward, // 本轮每人可获取的奖励
                    num: neilNum[period], // 本轮全球分红总人数
                    amount: amount, // 本轮全球分红总金额, 从全球分红奖池扣除
                    endTime: endTime // 本轮全球分红结束时间
                });
                dividendInfo[dividendRound] = dividendInfoStruct;

                // 全球分红清零
                jackpots[period].dividendPool = 0;
                emit ChangeSysPool("dividendPool", period, 2, amount, 0);
                emit CalcSysDividend(period, dividendRound, dividendStartTime, endTime, neilNum[period], reward, amount);
            }
            // 下轮开始时间 = 上轮结束时间 
            dividendStartTime = endTime;
        }
    }

    uint256 constant private leaderRate = 8; // 6-10代领导奖比例
    uint256 constant private managerRate = 5; // 无限代经理奖比例

    // 解冻捐款订单
    function unfreezeOrder(uint256 unfreezeID) public isRestart checkPauseUpgrade returns(string memory) {
        address userAddr = msg.sender;
        uint256 lastID = getLastID(userAddr);
        // 解冻订单不能关联自己
        require(unfreezeID != lastID, "Cannot be associated self");
        // 检查订单是否已解冻
        require(checkOrderUnFreeze(userAddr, unfreezeID), "Freezing time not full");
        // 检查订单是否标记过解冻
        require(!orders[userAddr][period][unfreezeID].isExtract, "Order has been extract");
        // 尾部订单已被关联使用过
        require(!orders[userAddr][period][lastID].isUse, "Latest order has been associated");
        uint256 amount = orders[userAddr][period][unfreezeID].amount;
        uint256 lastAmount = orders[userAddr][period][lastID].amount;
        // 尾部订单金额不能小于首部订单金额
        require(lastAmount >= amount, "Unfrozen amount is greater than the amount of the latest order");
        // 标记订单状态为已提取
        orders[userAddr][period][unfreezeID].isExtract = true;

        // 计算6-10代领导奖
        calcLeader(userAddr, unfreezeID);
        // 计算无限代经理奖
        calcManager(userAddr, unfreezeID);

        // 从互助基金奖池提现
        bool isDebt = drawSysHelpPool(amount);
        if (isDebt) {
            return "Withdraw failed, system Restart";
        }

        OrderInfoStruct storage _orderInfo = orderInfo[userAddr][period];
        // 更新用户场内本金总额, 本笔解冻订单金额也需要一起计算日率
        _orderInfo.fund = _orderInfo.fund.sub(amount);
        // 计算订单倍率
        uint256 rate = calcOrderRate(userAddr);
        // 更新用户订单日率
        _orderInfo.rate = rates[rate][0];

        // 尾部订单标记为已关联
        orders[userAddr][period][lastID].isUse = true;
        // 发放奖金
        require(address(token).safeTransfer(userAddr, amount), "Transfer failed");

        // 结算上期用户保险补偿总金额
        _calcRecover(userAddr);

        // 结算此订单能补偿的金额
        _calcRecoverByOrder(userAddr, amount);

        emit UnfreezeOrder(userAddr, period, unfreezeID, lastID, amount);
        return "Withdraw success";
    }

    // 结算此订单能补充的金额
    function _calcRecoverByOrder(address userAddr, uint256 amount) private {
        // 检查用户是否存在亏损
        if (recoverInfo[userAddr] != 0) {
            // 存在亏损
            // 计算保险补偿金额, 当前订单金额的10%
            uint256 recoverAmount = amount.mul(recoveOrderRate).div(100);
            // 补偿金额不超过亏损金额, 不能按照订单金额的10%算
            recoverAmount = min(recoverAmount, recoverInfo[userAddr]);
            // 记账
            recoverReward[userAddr] = recoverReward[userAddr].add(recoverAmount);
            // 扣除用户亏损
            recoverInfo[userAddr] = recoverInfo[userAddr].sub(recoverAmount);
            emit ChangePool("recoverReward", userAddr, period, 1, recoverAmount, recoverReward[userAddr]);
        }
    }

    // 补偿用户（补偿队列中的用户）
    function _recoverQueueUser() private {
        // 按补偿队列依次补偿用户, 优先保证队列中的用户能领取到补偿
        uint256 loss = recoverList[recoverDoneID].loss;
        if (currRecoverID != recoverDoneID && sysRecoverPool >= loss) {
            address userAddr = recoverList[recoverDoneID].userAddr;
            // 存在待补偿的用户且补偿基金足够, 门票在进入队列时已扣除, 无需重复扣除
            sysRecoverPool = sysRecoverPool.sub(loss);
            require(address(token).safeTransfer(userAddr, loss), "Transfer failed");
            // 已补偿的补偿队列编号递增
            recoverDoneID = recoverDoneID.add(1);
            // 用户补偿队列记账金额减少
            recoverListInfo[userAddr] = recoverListInfo[userAddr].sub(loss);
            emit ChangeRecoverQueue(userAddr, period, 2, loss);
            emit ChangeSysPool("sysRecoverPool", period, 2, loss, sysRecoverPool);
        }
    }

    // 提取保险补偿
    function drawRecoverReward() public checkPauseUpgrade {
        address userAddr = msg.sender;
        uint256 recoverAmount = recoverReward[userAddr];
        // 检查用户是否有可取款的保险奖
        if (recoverAmount != 0) {
            // 检查补偿基金是否足够, 或是否存在待补偿的用户
            if (sysRecoverPool < recoverAmount || currRecoverID != recoverDoneID) {
                // 余额不足/存在待补偿用户, 进入补偿队列
                // 进入队列之前扣除门票(保险补偿不计算在已取款奖金内)
                burnTicket(userAddr, recoverAmount, 0);
                // 进入队列
                RecoverListStruct memory recoverListStruct;
                recoverListStruct = RecoverListStruct({
                    userAddr: userAddr,
                    loss: recoverAmount
                });
                recoverList[currRecoverID] = recoverListStruct;
                recoverListInfo[userAddr] = recoverListInfo[userAddr].add(recoverAmount);
                currRecoverID = currRecoverID.add(1);
                emit ChangeRecoverQueue(userAddr, period, 1, recoverAmount);
            } else {
                // 补偿用户, 本笔订单直接补偿亏损金额, 因为不用进入队列, 所以需要扣除门票
                sysRecoverPool = sysRecoverPool.sub(recoverAmount);
                sendReward(userAddr, recoverAmount, 0);
                emit ChangeSysPool("sysRecoverPool", period, 2, recoverAmount, sysRecoverPool);
            }
            // 扣除可取款的保险奖
            recoverReward[userAddr] = 0;
            emit ChangePool("recoverReward", userAddr, period, 2, recoverAmount, 0);
        }
    }

    // 检查订单是否已解冻
    function checkOrderUnFreeze(address userAddr, uint256 unfreezeID) public view returns(bool) {
        uint256 freezeDay = orders[userAddr][period][unfreezeID].freezeDay;
        uint256 createdAt = orders[userAddr][period][unfreezeID].createdAt;
        return now >= createdAt.add(freezeDay.mul(dayToSecond));
    }

    // 计算6-10代领导奖
    function calcLeader(address userAddr, uint256 unfreezeID) private {
        // 未启用6-10代领导奖
        if (!enableLeader) {
            return;
        }
        uint256 refLen = users[userAddr].refs.length;
        uint256 len = min(refLen, 10);
        uint256 freezeDay = orders[userAddr][period][unfreezeID].freezeDay;
        uint256 rate = orderInfo[userAddr][period].rate;
        uint256 amount = orders[userAddr][period][unfreezeID].amount;
        for (uint256 i = 5; i < len; i = i.add(1)){
            address item = users[userAddr].refs[refLen.sub(1).sub(i)];
            uint256 level = userInfo[item][period].level;
            // 职位为领导
            if (level >= 7) {
                // 计算烧伤
                uint256 amountTmp = 0;
                uint256 rateTmp = 0;
                (amountTmp, rateTmp) = calcBurn(item, amount, rate);
                // 6-10代领导奖: 订单金额 * 冻结期 * 日率 * 8%
                // 捐助奖
                uint256 _donate = amountTmp.mul(freezeDay).mul(rateTmp).div(1000);
                uint256 reward = _donate.mul(leaderRate).div(100);
                if(reward > 0) {
                    userReward[item][period].leader = userReward[item][period].leader.add(reward);
                    emit ChangePool("leader", item, period, 1, reward, userReward[item][period].leader);
                }
            }
        }
    }

    // 计算无限代经理奖
    function calcManager(address userAddr, uint256 unfreezeID) private {
        // 6-10代领导奖/无限代经理奖共用开关
        if (!enableLeader) {
            return;
        }
        uint256 refLen = users[userAddr].refs.length;
        uint256 len = min(refLen, depth);
        uint256 freezeDay = orders[userAddr][period][unfreezeID].freezeDay;
        uint256 rate = orderInfo[userAddr][period].rate;
        uint256 amount = orders[userAddr][period][unfreezeID].amount;
        for (uint256 i = 10; i < len; i = i.add(1)) {
            address item = users[userAddr].refs[refLen.sub(1).sub(i)];
            uint256 level = userInfo[item][period].level;
            // 职位为经理
            if (level >= 8) {
                // 计算烧伤
                uint256 amountTmp = 0;
                uint256 rateTmp = 0;
                (amountTmp, rateTmp) = calcBurn(item, amount, rate);
                // 无限代经理奖: 订单金额 * 冻结期 * 日率 * 5%
                // 捐助奖
                uint256 _donate = amountTmp.mul(freezeDay).mul(rateTmp).div(1000);
                uint256 reward = _donate.mul(managerRate).div(100);
                if(reward > 0) {
                    userReward[item][period].manager = userReward[item][period].manager.add(reward);
                    emit ChangePool("manager", item, period, 1, reward, userReward[item][period].manager);
                    // 向上查找到第一位经理即结束查找
                    break;
                }
            }
        }
    }

    // 从互助基金奖池提现
    function drawSysHelpPool(uint256 amount) private returns(bool) {
        // 检查互助奖池是否足够支付奖金
        if (helpPool[period] < amount) {
            // 不足以支付, 重启系统
            _restart();
            return true;
        }

        // 更新互助奖池
        updateHelpPool(amount, false);
        return false;
    }

    // 重启系统
    function _restart() private {
        restartStartTime = now;
        allowRestart = true;
        // 开启终极竞赛奖
        enableSuper[period] = true;

        emit ChangeSwitch("allowRestart", period, msg.sender, allowRestart);
    }

    // 一键提取奖金
    function allDraw() public checkPauseUpgrade {
        // 全球经理->提取全球分红
        if(userInfo[msg.sender][period].level == 9) {
            drawDividend(dividendDrawIdx[msg.sender], dividendRound);
        }
        // 提取其它奖金(竞猜/竞赛/任务)
        drawOtherReward();
        // 提取保险补偿
        drawRecoverReward();
        // 重启过渡期不允许提取互助基金
        if (allowRestart == false) {
            // 提取互助奖金
            _drawHelpPool(msg.sender);
        }
    }

    // 计算提取捐助奖
    function drawDonate(uint256 start, uint256 end) public isRestart checkPauseUpgrade returns(string memory) {
        address userAddr = msg.sender;
        // 计算捐助奖金
        _calcDonate(userAddr, start, end);
        // 提取捐助奖金
        return _drawDonate(userAddr);
    }

    // 计算捐助奖金, 发放已解冻天数的订单捐助奖金至用户奖池
    function _calcDonate(address userAddr, uint256 start, uint256 end) private {
        uint256 reward = 0;
        // 订单数量不能超过50
        require(start.add(49) >= end, "Order quantity cannot exceed 50");
        // 虽然订单进入有先后, 但是订单冻结期长短不一, 可能后进先解冻, 还是需要等待先进入的订单解冻
        for (uint256 i = start; i <= end; i = i.add(1)){
            OrderStruct storage itemOrder = orders[userAddr][period][i];
            uint256 createdAt = itemOrder.createdAt;
            uint256 updateDay = itemOrder.updateDay;
            uint256 freezeDay = itemOrder.freezeDay;
            // 处理已解冻天数的订单, 完全解冻的无需处理
            if (updateDay != freezeDay) {
                uint256 amount = itemOrder.amount;
                // 解冻时间(秒)
                uint256 tmpTime = min(now, createdAt.add(freezeDay.mul(dayToSecond)));
                // 已解冻天数(天)
                uint256 tmpDay = tmpTime.sub(createdAt).sub(updateDay.mul(dayToSecond)).div(dayToSecond);
                // 更新时间更新为已发放的天数, 如已解冻2天, 该值为2, 下次计算从3开始计算
                itemOrder.updateDay = min(freezeDay, updateDay.add(tmpDay));
                // 该订单已解冻捐助奖: 订单金额 * 解冻天数(最大不超过冻结期) * 日率
                reward = reward.add(amount.mul(min(freezeDay, tmpDay)).mul(itemOrder.rate).div(1000));
                emit ChangeDonate(userAddr, period, i, itemOrder.updateDay);
            }
        }
        if(reward > 0) {
            // 发放捐助奖金至用户奖池
            userReward[userAddr][period].donate = userReward[userAddr][period].donate.add(reward);
            emit ChangePool("donate", userAddr, period, 1, reward, userReward[userAddr][period].donate);
        }
    }

    // 提取捐助奖
    function _drawDonate(address userAddr) private returns(string memory) {
        uint256 amount = userReward[userAddr][period].donate; // 捐助奖金
        if(amount == 0) {
            return "No reward to draw";
        }

        // 从互助基金奖池提现
        bool isDebt = drawSysHelpPool(amount);
        if (isDebt) {
            return "Withdraw failed, system Restart";
        }

        // 捐助奖
        userReward[userAddr][period].donate = 0;
        emit ChangePool("donate", userAddr, period, 2, amount, 0);

        // 更新用户解冻奖金合计总额, 本次提现金额也需要一起计算日率
        orderInfo[userAddr][period].earn = orderInfo[userAddr][period].earn.add(amount);
        // 计算订单倍率
        uint256 rate = calcOrderRate(userAddr);
        // 更新用户订单日率
        orderInfo[userAddr][period].rate = rates[rate][0];

        // 发放奖金
        sendReward(userAddr, amount, amount);
        return "Withdraw success";
    }

    /**
    * 计算每日竞赛奖:用户地址,分类,业绩,获奖时间,获奖等级,获奖金额
    * 分类:1(新激活的成员捐款总金额的竞赛)/2(邀请新激活的成员捐款总金额的竞赛)/3(邀请新激活的成员总人数的竞赛)
     */
    function calcContest(
        address[] memory addrs,
        uint256[] memory types,
        uint256[] memory values,
        uint256[] memory times,
        uint256[] memory levels,
        uint256[] memory amount
    ) public checkPauseUpgrade checkAuth(1021) {
        // 数量不超过30
        require(addrs.length <= 30, "Quantity cannot exceed 30");
        // 地址数量和分类不匹配
        require(addrs.length == types.length, "The number of addresses does not match the type");
        // 地址数量和业绩不匹配
        require(addrs.length == values.length, "Address number does not match performance");
        // 地址数量和获奖时间不匹配
        require(addrs.length == times.length, "The number of addresses does not match the winning time");
        // 地址数量和获奖等级不匹配
        require(addrs.length == levels.length, "The number of addresses does not match the award level");
        // 地址数量和获奖金额不匹配
        require(addrs.length == amount.length, "The number of addresses does not match the winning amount");
        for (uint256 i = 0; i < addrs.length; i = i.add(1)) {
            address item = addrs[i];
            userReward[item][period].contest = userReward[item][period].contest.add(amount[i]);
            emit ChangePool("contest", item, period, 1, amount[i], userReward[item][period].contest);
            emit CalcContest(item, period, types[i], values[i], times[i], levels[i], amount[i]);
        }
    }

    /**
    * 计算每日竞猜奖:用户地址,分类,竞猜内容,竞猜轮次,获奖等级,获奖金额
    * 分类: 1(竞猜一预测明日合约流入量)/2(预测明日系统注册量)
     */
    function calcGuess(
        address[] memory addrs,
        uint256[] memory types,
        uint256[] memory values,
        uint256[] memory rounds,
        uint256[] memory levels,
        uint256[] memory amount
    ) public checkPauseUpgrade checkAuth(1022) {
        // 数量不超过30
        require(addrs.length <= 30, "Quantity cannot exceed 30");
        // 地址数量和分类不匹配
        require(addrs.length == types.length, "The number of addresses does not match the type");
        // 地址数量和竞猜内容不匹配
        require(addrs.length == values.length, "The number of addresses does not match the content of the quiz");
        // 地址数量和竞猜轮次不匹配
        require(addrs.length == rounds.length, "The number of addresses does not match the number of quiz periods.");
        // 地址数量和获奖等级不匹配
        require(addrs.length == levels.length, "The number of addresses does not match the award level");
        // 地址数量和获奖金额不匹配
        require(addrs.length == amount.length, "The number of addresses does not match the winning amount");
        for (uint256 i = 0; i < addrs.length; i = i.add(1)) {
            address item = addrs[i];
            userReward[item][period].guess = userReward[item][period].guess.add(amount[i]);
            emit ChangePool("guess", item, period, 1, amount[i], userReward[item][period].guess);
            emit CalcGuess(item, period, types[i], values[i], rounds[i], levels[i], amount[i]);
        }
    }

    // 参与竞猜:预测明日系统注册量;预测明日合约流入量
    function doGuess(uint256 count, uint256 amount) public isRestart checkPauseUpgrade returns(bool){
        uint256 len = min(getUserOrderNum(msg.sender), 30);
        // 检查最后30笔订单，是否有冻结中的订单
        for(uint256 i = 0; i < len; i = i.add(1)) {
            uint256 id = orders[msg.sender][period].length.sub(i).sub(1);
            // 是否解冻
            bool isUnFreeze = checkOrderUnFreeze(msg.sender, id);
            if(!isUnFreeze) {
                // 轮次计算
                uint256 round = now.sub(eachStartTime[period]).div(dayToSecond);
                emit DoGuess(msg.sender, period, round, count, amount);
                return true;
            }
        }
        return false;
    }

    uint256 public useTaskAmount = 0; // 记录已分发的任务金额, 提取任务基金后, 扣除此金额

    // 提交任务链接
    function doTask(string memory link) public checkPauseUpgrade {
        emit DoTask(msg.sender, period, link);
    }

    /**
    * 计算任务获奖记录:用户地址,奖池分类(1在线任务/2离线任务),任务分类,任务编码,防伪码,获奖金额
    * 奖池分类: 1在线任务/2离线任务
    * 任务分类: 1网络任务/2幸福信视频任务/3离线任务/4定制任务/收集任务
     */
    function calcTask(
        address[] memory addrs,
        uint256[] memory types,
        uint256[] memory taskTypes,
        bytes32[] memory taskIds,
        bytes32[] memory securitys,
        uint256[] memory amount
        ) public checkPauseUpgrade checkAuth(1023) {
        // 数量不超过30
        require(addrs.length <= 30, "Quantity cannot exceed 30");
        // 地址数量和奖池分类不匹配
        require(addrs.length == types.length, "The number of addresses does not match the category of the prize pool");
        // 地址数量和任务分类不匹配
        require(addrs.length == taskTypes.length, "The number of addresses does not match task classification ");
        // 地址数量和任务编码不匹配
        require(addrs.length == taskIds.length, "The number of addresses does not match the task code");
        // 地址数量和防伪码不匹配
        require(addrs.length == securitys.length, "The number of addresses does not match the security code");
        // 地址数量和获奖金额不匹配
        require(addrs.length == amount.length, "The number of addresses does not match the content of the quiz");
        for (uint256 i = 0; i < addrs.length; i = i.add(1)) {
            address item = addrs[i];
            if(types[i] == 1) {
                userReward[item][period].task = userReward[item][period].task.add(amount[i]);
                emit ChangePool("task", item, period, 1, amount[i], userReward[item][period].task);
            } else {
                userReward[item][period].offlineTask = userReward[item][period].offlineTask.add(amount[i]);
                emit ChangePool("offlineTask", item, period, 1, amount[i], userReward[item][period].offlineTask);
            }
            useTaskAmount = useTaskAmount.add(amount[i]);
            emit CalcTask(item, period, taskTypes[i], taskIds[i], securitys[i], amount[i]);
        }
    }

    mapping(address => mapping(uint256 => uint256)) public salary; // 用户地址 -> 工资周期 -> 工资金额

    // 计算员工工资:员工地址;员工工资;工资轮次
    function calcSalary(address[] memory addrs, uint256[] memory amount, uint256[] memory rounds) public checkPauseUpgrade checkAuth(1023) {
        // 数量不超过30
        require(addrs.length <= 30, "Quantity cannot exceed 30");
        // 地址数量和获奖金额不匹配
        require(addrs.length == amount.length, "The number of addresses does not match the winning amount");
        // 地址数量和工资周期不匹配
        require(addrs.length == rounds.length, "The number of addresses does not match the wage cycle");
        for (uint256 i = 0; i < addrs.length; i = i.add(1)) {
            address addr = addrs[i];
            uint256 round = rounds[i];
            uint256 _amount = amount[i];
            salary[addr][round] = salary[addr][round].add(_amount);
            useTaskAmount = useTaskAmount.add(_amount);
            emit ChangeSalary(addr, period, round, 1, _amount);
        }
    }

    // 提取员工工资
    function drawSalary(uint256 round) public checkPauseUpgrade {
        uint256 amount = salary[msg.sender][round];
        // 工资余额不足
        require(amount > 0, "Insufficient wage balance");
        salary[msg.sender][round] = 0;
        useTaskAmount = useTaskAmount.sub(amount);
        taskPayPool = taskPayPool.sub(amount);
        // 发放奖励
        require(address(token).safeTransfer(msg.sender, amount), "Transfer failed");
        emit ChangeSalary(msg.sender, period, round, 2, 0);
        emit ChangeSysPool("taskPayPool", period, 2, amount, taskPayPool);
    }

    mapping (address => uint256) private recoverPeriod; // 用户地址 -> 系统期数

    // 查询用户亏损总额(升级合约调用):用户地址,系统周期。
    function getRecover(address userAddr, uint256 _period) public view returns(uint256) {
        uint256 fund = orderInfo[userAddr][_period].fund;
        uint256 ticket = destroyOf[userAddr][_period];
        // 上期已取款奖金总额(不包含离线任务奖)
        uint256 reward = orderInfo[userAddr][_period].reward;
        // 上期亏损额 = 上期未取款本金 + 已消耗门票 - 上期已取款奖金总额
        uint256 loss = fund.add(ticket).sub(reward);
        //亏损额 > 0(有亏损); 补偿金总额 = 亏损额 + 上期未补偿完的补偿基金
        if(loss > 0) {
            return loss.add(recoverInfo[userAddr]);
        }
        // 亏损额 <= 0 (有赚钱); 补偿总金额 = 上期未补偿完的补偿基金
        return recoverInfo[userAddr];
    }

    // 计算保险补偿基金
    function _calcRecover(address userAddr) private {
        // 检查是否进入补偿周期
        uint256 prevTmp = recoverPeriod[userAddr];
        uint256 prev = prevTmp != 0 ? prevTmp : 1;
        if (prev < period) {
            // 补偿金总额
            uint256 amount = getRecover(userAddr, prev);
            recoverInfo[userAddr] = amount;
            // 设定用户补偿周期, 不再重复补偿
            recoverPeriod[userAddr] = prev.add(1);
            emit ChagngeRecover(userAddr, prev, period, recoverInfo[userAddr]);
        }
    }

    uint256[] private mentorRate = [50, 30, 20]; // 经理导师奖金比例

    // 计算经理导师奖
    function _calcMentor(address userAddr, uint256 amount) private {
        if(amount == 0) {
            return;
        }
        uint256 refLen = users[userAddr].refs.length;
        uint256 len = min(refLen, depth);

        // 紧缩第一位经理50%, 第二位经理30%, 第三位经理20%
        uint256 managerCount = 0;
        for (uint256 i = 0; i < len; i = i.add(1)) {
            address item = users[userAddr].refs[refLen.sub(1).sub(i)];
            uint256 level = userInfo[item][period].level;
            // 职位为经理
            if (level >= 8) {
                uint256 reward = amount.mul(mentorRate[managerCount]).div(100);
                if(reward > 0) {
                    userReward[item][period].mentor = userReward[item][period].mentor.add(reward);
                    managerCount = managerCount.add(1);
                    emit ChangePool("mentor", item, period, 1, reward, userReward[item][period].mentor);
                }
            }
            if (managerCount == 3) {
                // 向上查找到第三位经理即结束查找
                break;
            }
        }
    }

    // 提取互助奖金
    function drawHelpPool() public isRestart checkPauseUpgrade returns(string memory) {
        return _drawHelpPool(msg.sender);
    }

    // 提取互助奖金
    function _drawHelpPool(address userAddr) private returns(string memory) {
        UserPoolStruct storage userPool = userReward[userAddr][period];
        uint256 recommend = userPool.recommend; // 1-5代推荐奖
        uint256 leader = userPool.leader; // 6-10代领导奖
        uint256 manager = userPool.manager; // 无限代经理奖
        uint256 mentor = userPool.mentor; // 经理导师奖
        uint256 amount = recommend.add(leader).add(manager).add(mentor); // 需要计算日率的奖金

        if(amount == 0) {
            return "No reward to draw";
        }

        // 从互助基金奖池提现
        bool isDebt = drawSysHelpPool(amount);
        if (isDebt) {
            return "Withdraw failed, system Restart";
        }

        // 计算经理导师奖-经理职位成员取款一笔"无限代经理奖"时结算
        _calcMentor(userAddr, manager);

        // 更新用户解冻奖金合计总额, 本次提现金额也需要一起计算日率
        orderInfo[userAddr][period].earn = orderInfo[userAddr][period].earn.add(amount);
        // 计算订单倍率
        uint256 rate = calcOrderRate(userAddr);
        // 更新用户订单日率
        orderInfo[userAddr][period].rate = rates[rate][0];
        if(recommend > 0) {
            // 1-5代推荐奖
            userPool.recommend = 0;
            emit ChangePool("recommend", userAddr, period, 2, recommend, 0);
        }
        if(leader > 0) {
            // 6-10代领导奖
            userPool.leader = 0;
            emit ChangePool("leader", userAddr, period, 2, leader, 0);
        }
        if(manager > 0) {
            // 无限代经理奖
            userPool.manager = 0;
            emit ChangePool("manager", userAddr, period, 2, manager, 0);
        }
        if(mentor > 0) {
            // 经理导师奖
            userPool.mentor = 0;
            emit ChangePool("mentor", userAddr, period, 2, mentor, 0);
        }
        // 发放奖金
        sendReward(userAddr, amount, amount);
        return "Withdraw success";
    }

    mapping(address => uint256) public dividendDrawIdx; // 用户领取全球分红开始位置, 用于记录用户下一次该从第几轮次开始领取

    // 提取全球分红
    function drawDividend(uint256 start, uint256 end) public checkPauseUpgrade {
        address userAddr = msg.sender;
        // 轮数不超过50
        require(start.add(49) >= end, "Number of periods cannot exceed 50");
        uint256 tmpStart = max(start, dividendDrawIdx[userAddr]);
        uint256 tmpEnd = min(end, dividendRound);
        uint256 reward = 0;
        for (uint256 i = tmpStart; i <= tmpEnd; i = i.add(1)) {
            // 检查是否在限定时间内成为全球经理
            // 可获得全球分红的条件:
            // 正常晋升: level等级为全球经理且晋升等级时间小于等于结束时间
            if (
                userInfo[userAddr][period].level == 9 && neilNormalTime[userAddr] <= dividendInfo[i].endTime
            ) {
                reward = reward.add(dividendInfo[i].reward);
                emit ChangePool("dividendReward", userAddr, period, i, dividendInfo[i].reward, 0);
            }
        }
        if(reward != 0) {
            // 发放全球分红奖金至用户地址
            dividendDrawIdx[userAddr] = tmpEnd.add(1);
            sendReward(userAddr, reward, reward);
        }
    }

    mapping(uint256 => bool) enableSuper; // 终极竞赛大奖开奖状态, 系统周期 -> 是否触发开奖
    uint256 constant private superPageSize = 100; // 终极竞赛大奖每轮最大计算的订单数
    mapping(uint256 => uint256) public superDrawIndex; // 终极竞赛大奖每期已提取的索引, 系统期数 -> 已提取索引

    // 计算提取终极竞赛大奖
    function drawSuper() public checkPauseUpgrade {
        // 头等奖未开奖
        require(enableSuper[period], "Ultimate prize is not open");
        // 计算
        _calcSuper(period);
        // 提取
        _drawSuper(msg.sender, period);
    }

    // 计算终极竞赛大奖
    function _calcSuper(uint256 _period) private {
        uint256 tmpSuperPool = jackpots[_period].superPool;
        if(tmpSuperPool != 0) {
            // 计算当前轮次所有用户奖励并记账
            superDrawIndex[_period] = superDrawIndex[_period].add(1);
            uint256 page = superDrawIndex[_period];

            // eg. 一共11笔订单[0,11), 每轮3笔, 第1轮: [8,11), 2: [5,8), 3: [2,5), 4: [0,2)
            // 第1轮: start = 11 - (1 * 3), end = start + 3, index = end - i + start
            uint256 start = 0;
            uint256 end = 0;
            uint256 skip = page.mul(superPageSize);
            if (orderList[_period].length > skip) {
                start = orderList[_period].length.sub(skip);
                end = start.add(superPageSize);
            } else {
                uint256 exceed = skip.sub(orderList[_period].length);
                end = start.add(superPageSize).sub(exceed);
            }

            // 本轮订单列表累计金额
            uint256 amountTotal = 0;
            for (uint256 i = start; i < end; i = i.add(1)) {
                // 订单列表倒序查找
                uint256 idx = end.sub(i).add(start).sub(1);
                // 最后一笔获得订单本金的5倍, 倒数第二笔向前推算获得订单本金的3倍
                uint256 ratio = (i == start && page == 1) ? 5 : 3;
                uint256 userAmount = orderList[_period][idx].amount.mul(ratio);
                amountTotal = amountTotal.add(userAmount);
                // 检查终极竞赛大奖金额是否足够分配
                if (amountTotal > tmpSuperPool) {
                    // 不足发放一笔奖金, 则将剩余资金滚动到下一期
                    jackpots[_period].superPool = 0;
                    uint256 exceed = userAmount.sub(amountTotal.sub(tmpSuperPool));
                    uint256 nextPeriod = _period.add(1);
                    uint256 amount = jackpots[nextPeriod].superPool.add(exceed);
                    jackpots[nextPeriod].superPool = jackpots[nextPeriod].superPool.add(amount);
                    emit ChangeSysPool("superPool", _period, 2, amount, 0);
                    emit ChangeSysPool("superPool", nextPeriod, 1, amount, jackpots[nextPeriod].superPool);
                    break;
                }
                // 给用户记账
                address orderAddr = orderList[_period][idx].userAddr;
                userReward[orderAddr][period].superReward = userReward[orderAddr][period].superReward.add(userAmount);
                emit ChangePool("superReward", orderAddr, _period, 1, userAmount, userReward[orderAddr][period].superReward);
            }
            // 扣除终极竞赛大奖余额
            if (jackpots[_period].superPool != 0 && amountTotal != 0) {
                jackpots[_period].superPool = jackpots[_period].superPool.sub(amountTotal);
                emit ChangeSysPool("superPool", _period, 2, amountTotal, jackpots[_period].superPool);
            }
        }
        emit ChangeUnit("superDrawIndex", period, msg.sender, superDrawIndex[_period]);
    }

    // 提取终极竞赛大奖
    function _drawSuper(address userAddr, uint256 _period) private {
        // 奖励不为0, 则发放奖励给用户
        uint256 reward = userReward[userAddr][_period].superReward;
        if (reward != 0) {
            userReward[userAddr][_period].superReward = 0;
            sendReward(userAddr, reward, reward);
            emit ChangePool("superReward", userAddr, _period, 2, reward, 0);
        }
    }

    // 提取其他奖金
    function drawOtherReward() public checkPauseUpgrade {
        address userAddr = msg.sender;
        UserPoolStruct storage userPool = userReward[userAddr][period];
        uint256 contest = userPool.contest; // 每日竞赛奖
        uint256 guess = userPool.guess; // 每日竞猜奖
        uint256 task = userPool.task; // 任务奖金
        uint256 offlineTask = userPool.offlineTask; // 离线任务奖金
        uint256 reward = contest.add(guess).add(task);
        uint256 amount = reward.add(offlineTask);
        if(amount == 0) {
            return;
        }
        // 扣除竞赛奖
        if(contest > 0) {
            userPool.contest = 0;
            contestPool = contestPool.sub(contest);
            emit ChangePool("contest", userAddr, period, 2, contest, 0);
            emit ChangeSysPool("contestPool", period, 2, contest, contestPool);
        }
        // 扣除竞猜奖
        if(guess > 0) {
            userPool.guess = 0;
            guessPool = guessPool.sub(contest);
            emit ChangePool("guess", userAddr, period, 2, guess, 0);
            emit ChangeSysPool("guessPool", period, 2, contest, guessPool);
        }
        // 扣除任务奖
        if(task > 0) {
            useTaskAmount = useTaskAmount.sub(task);
            taskPayPool = taskPayPool.sub(task);
            userPool.task = 0;
            emit ChangePool("task", userAddr, period, 2, task, 0);
            emit ChangeSysPool("taskPayPool", period, 2, task, taskPayPool);
        }
        // 扣除离线任务奖
        if(offlineTask > 0) {
            useTaskAmount = useTaskAmount.sub(offlineTask);
            taskPayPool = taskPayPool.sub(offlineTask);
            userPool.offlineTask = 0;
            emit ChangePool("offlineTask", userAddr, period, 2, offlineTask, 0);
            emit ChangeSysPool("taskPayPool", period, 2, offlineTask, taskPayPool);
        }
        // 发放奖金
        sendReward(userAddr, amount, reward);
    }

    // 提案数据结构定义
    struct ProposalStruct {
        uint256 yes; // 赞成票
        uint256 no; // 反对票
        uint256 time; // 有效期(秒), 1-9预留, 1 -> 投票拒绝, 2 -> 投票通过, 3 -> 投票已执行
        uint256 createdAt; // 创建时间
        uint256 auth; // 可投票的权限集合
        address addr; // 地址
        uint256 proposalType; // 提案类型: 1 -> 暂停提案 2 -> 升级提案 大于3 -> 提案冻结用户的时长
    }
    mapping(uint256 => ProposalStruct) public proposals; // 提案列表
    mapping(address => mapping(uint256 => bool)) public isVote; // 用户是否已投票
    uint256 public proposalIndex = 0 ; // 提案索引

    mapping(uint256 => mapping(address => uint256)) public unfreezeUserTime; // 用户解冻信息: 系统周期 -> 用户地址 -> 解冻时间

    // 是否是合约地址
    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    // 发起提案
    function startProposal(uint256 index, uint256 time, uint256 auth, address addr, uint256 proposalType) public checkUpgrade checkAuth(1008) {
        // 编号已被使用
        require(proposalIndex == index, "Number has been used");
        // 投票权限不合法
        require(auth >= 1 && auth <= 3, "Illegal voting permission parameter");
        // 投票有效期不合法
        require(time > 10 && time <= 999999 days, "Illegal voting validity parameter");
        // 合约地址不合法
        require(proposalType != 2 || isContract(addr), "Illegal contract address");
        // 创建提案
        ProposalStruct memory proposalStruct;
        proposalStruct = ProposalStruct({
            yes: 0,
            no: 0,
            time: time,
            createdAt: now,
            auth: auth,
            addr: addr,
            proposalType: proposalType
        });
        proposals[proposalIndex] = proposalStruct;
        proposalIndex = proposalIndex.add(1);
        emit StartProposal(msg.sender, index, time, auth, addr, proposalType);
    }

    // 投票
    function vote(uint256 index, bool voteStatus) public checkUpgrade {
        address userAddr = msg.sender;
        ProposalStruct storage proposal = proposals[index];
        // 编号不存在
        require(proposal.createdAt != 0, "Number does not exist");
        // 提案已结束
        require(proposal.time > 10, "Proposal is over");
        // 提案已过期
        require(proposal.createdAt.add(proposal.time) >= now, "Proposal has expired");
        // 已投过票
        require(isVote[userAddr][index] == false, "Already voted");
        // 权限不足
        require(checkVoteAuth(userAddr, index), "Insufficient authority");
        // 用户投票
        isVote[userAddr][index] = true;
        // 检查投票结果
        if (voteStatus) {
            proposal.yes = proposal.yes.add(1);
        } else {
            proposal.no = proposal.no.add(1);
        }
        uint256 result = checkVoteResult(index);
        if (result == 1 || result == 2) {
            // 记录投票结果
            proposal.time = result;
            emit ChangeProposalStatus(userAddr, index, result);

            // 投票通过->冻结用户
            if(result == 2 && proposal.proposalType >= 3) {
                proposal.time = 3;
                // 领导及以上用户需要减少用户总数
                _resetAfterLevel(proposal.addr);
                // 重置职位
                userInfo[proposal.addr][period].level = 1;
                // 记录解冻日期
                unfreezeUserTime[period][proposal.addr] = now.add(proposal.proposalType);
                emit ChangeLevel(userAddr, period, 5, 1);
                emit ChangeFreezeUser(msg.sender, userAddr, period, 1, unfreezeUserTime[period][proposal.addr]);
                emit ChangeProposalStatus(msg.sender, index, 3);
            }
        }
        emit VoteProposal(userAddr, index, voteStatus);
    }

    bool public isPause = false; // 暂停合约状态
    bool public isUpgrade = false; // 升级合约状态

    // 执行暂停提案
    function execPauseProposal(uint256 index) public checkUpgrade checkAuth(1018) {
        // 提案未通过
        require(proposals[index].time == 2, "Proposal was not passed");
        if (proposals[index].proposalType == 1) {
            // 提案通过, 并且提案为暂停合约
            isPause = true;
            proposals[index].time = 3;
            emit ChangeProposalStatus(msg.sender, index, 3);
            emit ChangeSwitch("isPause", period, msg.sender, isPause);
        }
    }

    // 执行升级提案
    function execUpgradeProposal(uint256 index) public checkUpgrade checkAuth(1020) {
        // 提案未通过
        require(proposals[index].time == 2, "Proposal was not passed");
        // 未在重启过渡期或合约未暂停
        require(allowRestart || isPause, "Not in restart transition period or contract not suspended");
        if (proposals[index].proposalType == 2) {
            // 提案通过, 重启过渡期中或者合约暂停中, 执行升级合约提案
            // 设置授权合约地址
            licenseContract[proposals[index].addr] = true;
            // 将资金转移到授权合约
            require(address(token).safeTransfer(proposals[index].addr, token.balanceOf(address(this))), "Transfer failed");
            proposals[index].time = 3;
            isUpgrade = true;
            emit ChangeProposalStatus(msg.sender, index, 3);
            emit ChangeLicenseAddr(msg.sender, proposals[index].addr, true);
        }
    }

    // 取消暂停
    function cancelPause() public checkUpgrade checkAuth(1009) {
        if (isPause) {
            isPause = false;
        }
    }

    // 检查投票权限
    function checkVoteAuth(address userAddr, uint256 index) public view returns(bool) {
        uint256 level = userInfo[userAddr][period].level;
        uint256 auth = proposals[index].auth;
        // 权限集合: 1 -> 全球经理, 2 -> 全球经理 + 经理人, 3 -> 全球经理 + 经理人 + 领导人
        if (
            (auth == 1 && level >= 9) ||
            (auth == 2 && level >= 8) ||
            (auth == 3 && level >= 7)
        ) {
            return true;
        }
        return false;
    }

    // 检查投票结果
    function checkVoteResult(uint256 index) public view returns(uint256) {
        uint256 auth = proposals[index].auth;
        uint256 yes = proposals[index].yes;
        uint256 no = proposals[index].no;
        uint256 count = 0;
        uint256 yesRate = 0;
        if (auth == 1) {
            // 全球经理
            count = neilNum[period];
            yesRate = 60;
        } else if (auth == 2) {
            // 全球经理 + 经理
            count = neilNum[period].add(managerNum[period]);
            yesRate = 50;
        } else if (auth == 3) {
            // 全球经理 + 经理 + 领导人
            count = neilNum[period].add(managerNum[period]).add(leaderNum[period]);
            yesRate = 40;
        }
        // 检查投票拒绝
        if (no.mul(100).div(count) >= 100 - yesRate) {
            return 1;
        }
        // 检查投票通过
        if (yes.mul(100).div(count) >= yesRate) {
            return 2;
        }
        return 0;
    }

    address public owner; // 超级管理员
    mapping(address => mapping(uint256 => bool)) public master; // 管理员, 管理员地址 -> 操作权限 -> 是否授权管理权, 用于批量收回权限
    mapping(address => address) public worker; // 执行者, 执行者地址 -> 上级管理员地址
    mapping(address => mapping(uint256 => bool)) private auths; // 权限集合, 执行者地址 -> 操作权限 -> 是否授权执行权, 操作权限从0-n进行编号

    // 检查权限, 参数为操作权限编号
    modifier checkAuth(uint256 authNum) {
        // 非超级管理员权限或未被授予权限
        require(msg.sender == owner || (master[worker[msg.sender]][authNum] && auths[msg.sender][authNum]), "Non super administrator or not granted permission");
        _;
    }

    // 检查超级管理员
    modifier checkOwner() {
        // 非超级管理员权限
        require(msg.sender == owner, "Non super administrator rights");
        _;
    }

    // 检查合约是否处于暂停状态和升级状态(升级后，所有功能不能用除注册,授权新合约地址,收回新合约地址外)
    modifier checkPauseUpgrade() {
        // 合约处于暂停状态
        require(isPause == false, "Contract is suspended");
        // 合约处于升级状态
        require(isUpgrade == false, "Contract is in a state of upgrading");
        _;
    }

    // 检查合约是否处于升级状态，
    modifier checkUpgrade() {
        // 合约处于升级状态
        require(isUpgrade == false, "Contract is in a state of upgrading");
        _;
    }

    // 检查是否有执行权
    function checkWorkAuth(address userAddr, uint256 authNum) public view returns (bool) {
        return userAddr == owner || master[worker[userAddr]][authNum] && auths[userAddr][authNum];
    }

    // 分配管理员权限
    function addMasterAuth(address _masterAddr, uint256[] memory _auths) public checkOwner {
        // 数量不超过30
        require(_auths.length <= 30, "Quantity cannot exceed 30");
        for(uint256 i = 0; i < _auths.length; i = i.add(1)) {
            if(master[_masterAddr][_auths[i]] != true) {
                // 分配管理员的管理权限
                master[_masterAddr][_auths[i]] = true;
                // 指定管理员的上级管理员为自身
                worker[_masterAddr] = _masterAddr;
                // 分配管理员的执行权限
                auths[_masterAddr][_auths[i]] = true;
                emit ChangeAuth(msg.sender, _masterAddr, 1, 1, _auths[i]);
            }
        }
    }

    // 收回管理员权限
    function removeMasterAuth(address _masterAddr, uint256[] memory _auths) public checkOwner {
        // 数量不超过30
        require(_auths.length <= 30, "Quantity cannot exceed 30");
        for(uint256 i = 0; i < _auths.length; i = i.add(1)) {
            // 收回管理员权限
            if(master[_masterAddr][_auths[i]] == true) {
                master[_masterAddr][_auths[i]] = false;
                emit ChangeAuth(msg.sender, _masterAddr, 2, 1, _auths[i]);
            }
        }
    }

    // 分配执行者权限, 限管理员
    function addWorkerAuth(address _workerAddr, uint256[] memory _auths) public {
        // 数量不超过30
        require(_auths.length <= 30, "Quantity cannot exceed 30");
        // 权限不足
        require(worker[_workerAddr] != _workerAddr, "Insufficient authority");
        for(uint256 i = 0; i < _auths.length; i = i.add(1)) {
            if(master[msg.sender][_auths[i]] && auths[_workerAddr][_auths[i]] != true) {
                auths[_workerAddr][_auths[i]] = true;
                worker[_workerAddr] = msg.sender;
                emit ChangeAuth(msg.sender, _workerAddr, 1, 2, _auths[i]);
            }
        }
    }

    // 收回执行者权限, 限管理员
    function removeWorkerAuth(address _workerAddr, uint256[] memory _auths) public {
        // 数量不超过30
        require(_auths.length <= 30, "Quantity cannot exceed 30");
        // 权限不足
        require(worker[_workerAddr] == msg.sender, "Insufficient authority");
        for(uint256 i = 0; i < _auths.length; i = i.add(1)) {
            if(master[msg.sender][_auths[i]] && auths[_workerAddr][_auths[i]] == true) {
                auths[_workerAddr][_auths[i]] = false;
                emit ChangeAuth(msg.sender, _workerAddr, 2, 2, _auths[i]);
            }
        }
    }

    // 配置任务奖池划转待支付奖池参数
    function updateTaskConfig(uint256 _limit, uint256 _transfer) public checkPauseUpgrade checkAuth(1002) {
        taskLimitAmount = _limit;
        taskAutoTranAmount = _transfer;
        emit ChangeAmount("taskLimitAmount", period, msg.sender, taskLimitAmount);
        emit ChangeAmount("taskAutoTranAmount", period, msg.sender, taskAutoTranAmount);
    }

    // 手动划拨, 任务奖池 -> 待支付奖池
    function taskToWaitPay(uint256 _amount) public checkPauseUpgrade checkAuth(1003) {
        taskPool = taskPool.sub(_amount);
        taskPayPool = taskPayPool.add(_amount);
        emit ChangeSysPool("taskPool", period, 2, _amount, taskPool);
        emit ChangeSysPool("taskPayPool", period, 1, _amount, taskPayPool);
    }

    // 手动划拨, 待支付奖池 -> 任务奖池
    function waitPayToTask(uint256 _amount) public checkPauseUpgrade checkAuth(1004) {
        // 已经分配过的任务金额不能划转
        require(taskPayPool.sub(useTaskAmount) >= _amount, "Task bonus has been allocated");
        taskPool = taskPool.add(_amount);
        taskPayPool = taskPayPool.sub(_amount);
        emit ChangeSysPool("taskPool", period, 1, _amount, taskPool);
        emit ChangeSysPool("taskPayPool", period, 2, _amount, taskPayPool);
    }

    // 手动划拨, 任务奖池 -> 互助奖池
    function taskToHelp(uint256 _amount) public checkPauseUpgrade checkAuth(1005) {
        taskPool = taskPool.sub(_amount);
        updateHelpPool(_amount, true);
        emit ChangeSysPool("taskPool", period, 2, _amount, taskPool);
    }

    // 关闭/开启竞赛基金
    function handleEnableContest(bool _status) public checkPauseUpgrade checkAuth(1006) {
        enableContest = _status;
        emit ChangeSwitch("enableContest", period, msg.sender, enableContest);
    }

    // 关闭/开启竞猜基金
    function handleEnableGuess(bool _status) public checkPauseUpgrade checkAuth(1007) {
        enableGuess = _status;
        emit ChangeSwitch("enableGuess", period, msg.sender, enableGuess);
    }

    // 关闭/开启任务基金
    function handleEnableTask(bool _status) public checkPauseUpgrade checkAuth(1014) {
        enableTask = _status;
        emit ChangeSwitch("enableTask", period, msg.sender, enableTask);
    }

    // 手动划拨, 竞猜基金 -> 互助奖池
    function guessToHelp(uint256 _amount) public checkPauseUpgrade checkAuth(1015) {
        guessPool = guessPool.sub(_amount);
        updateHelpPool(_amount, true);
        emit ChangeSysPool("guessPool", period, 2, _amount, guessPool);
    }

    // 手动划拨, 竞赛基金 -> 互助奖池
    function contestToHelp(uint256 _amount) public checkPauseUpgrade checkAuth(1016) {
        contestPool = contestPool.sub(_amount);
        updateHelpPool(_amount, true);
        emit ChangeSysPool("contestPool", period, 2, _amount, contestPool);
    }

    // 关闭/开启自动划转任务基金
    function handleWaitPaySwitch(bool _status) public checkPauseUpgrade checkAuth(1017) {
        enableTaskAutoTran = _status;
        emit ChangeSwitch("enableTaskAutoTran", period, msg.sender, enableTaskAutoTran);
    }

    // 设定重启过渡期
    function handleRestartTime(uint256 _restartTime) public checkPauseUpgrade checkAuth(1019) {
        // 重启过渡期不能超过365天
        require(_restartTime <= 365 days, 'Restart transition period cannot exceed 365 days');
        restartTime = _restartTime;
        emit ChangeUnit("restartTime", period, msg.sender, restartTime);
    }

    // 授权合约可调用团队结构的合约地址
    function addLicense(address contractAddr) public checkAuth(1024) {
        // 非法的合约地址
        require(isContract(contractAddr), "Illegal contract address");
        if(licenseContract[contractAddr] == false) {
            licenseContract[contractAddr] = true;
            emit ChangeLicenseAddr(msg.sender, contractAddr, true);
        }
    }

    // 超级管理员可收回授权合约地址权限
    function removeLicense(address contractAddr) public checkOwner {
        // 非法的合约地址
        require(isContract(contractAddr), "Illegal contract address");
        if(licenseContract[contractAddr] == true) {
            licenseContract[contractAddr] = false;
            emit ChangeLicenseAddr(msg.sender, contractAddr, false);
        }
    }

    // 解冻用户(提案投票被冻结的用户)
    function unfreezeUser(address userAddr) public checkPauseUpgrade checkAuth(1025) {
        unfreezeUserTime[period][userAddr] = 0;
        emit ChangeFreezeUser(msg.sender, userAddr, period, 2, 0);
    }

    // 配置运维生态基金地址
    function handleEcologyOpsAddr(address _ecologyOpsAddr) public checkPauseUpgrade checkAuth(1026) {
        ecologyOpsAddr = _ecologyOpsAddr;
        emit ChangeEcologyOpsAddr(msg.sender, period, ecologyOpsAddr);
    }

    // 修改更新上级等级时的最大层级数
    function handleDepthLevel(uint256 _depthLevel) public checkPauseUpgrade checkAuth(1027) {
        // 最大层级不超过80层
        require(_depthLevel <= depth, "Maximum level does not exceed 80");
        depthLevel = _depthLevel;
        emit ChangeUnit("depthLevel", period, msg.sender, depthLevel);
    }
}