// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Abc is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    // TODO
    // uint256 public INTERVAL_OF_EACH_PERIOD = 24 hours; // 每期间隔时间，当期结束之后再过间隔时间进入下一期
    // uint256 public CONTINUED_OF_EACH_PERIOD = 9 days; // 每期持续时间，在持续时间内未众筹满则本轮结束，发放奖励
    uint256 public INTERVAL_OF_EACH_PERIOD = 3 minutes; // 每期间隔时间，当期结束之后再过间隔时间进入下一期
    uint256 public CONTINUED_OF_EACH_PERIOD = 30 minutes; // 每期持续时间，在持续时间内未众筹满则本轮结束，发放奖励
    uint256 public withdrawFee = 10e18; // 每次提现扣除10个BZZONE作为手续费
    mapping(address => bool) public operator;
    
    
    IERC20 public wiki; // A币
    IERC20 public bzzone; // B币
    IERC20 public nft; // C币
    IERC20 public waxp; // waxp
    IERC20 public matebok; // 亏损释放代币
    address public teamer;
    address public canCaller;
    
    ////////////////////// 每轮信息 //////////////////////////////////
    uint256 public wheelNum; // 当前的轮数，从1开始，每次加1
    mapping(uint256 => WheelInfo) public wheelInfoMap; // wheelNum => WheelInfo
    struct WheelInfo {
        uint256 wheel; // 轮数
        uint256 startTime; // 开始时间
        uint256 endTime; // 结束时间
        uint256 endBlockNumber; // 结束区块高度
        uint256 periodNum; // 总期数，如果该轮已结束，表示该轮的最大期数；如果该轮未结束，表示当前期数，从1开始，每次加1
        uint256 isEnd; // 该轮是否已结束，0未结束，1已结束，当在9天内该期为众筹满是会结束当轮
        uint256 isSetTop10; // 是否已设置top10奖励，1是，0否
        uint256 isSetTop100; // 是否已设置top100奖励，1是，0否
    }

    ////////////////////// 每期信息 //////////////////////////////////
    mapping(uint256 => mapping(uint256 => PeriodInfo)) public periodInfoMap; // wheelNum => periodNum => PeriodInfo
    struct PeriodInfo {
        uint256 period; // 期数
        uint256 startTime; // 开始时间，每轮的第一期开始时间由外部设置，下一期的开始时间是上一期结束时间再加上24小时
        uint256 endTime; // 结束时间
        uint256 amount; // 最大众筹金额，保留1个token的整数，每轮的第一期众筹金额由外部设置，下一期的金额在前一期的基础上加25%，保留1个token的整数
        uint256 hasBuyAmount; // 本期已经够买的额度
        // uint256 isSettle; // 是否已结算，0未结算，1已结算
        address[] users; // 每期参与的地址数组
    }
    
    uint256 public userCount;
    mapping(uint256 => address) public userCountmap; // userCount => address
    ////////////////////// 总用户信息 //////////////////////////////////
    mapping(address => UserInfo) public userInfoMap; // address => UserInfo
    struct UserInfo {
        address refer; // 邀请人地址
        uint256 amount; // 总参与众筹的WIKI(A币)数量
        address[] directPushs; // 直推人地址数组
        uint256 canIndirect; // 是否能拿间推奖，1是，0否
        uint256 vipLevel; // VIP等级，由外部计算后更新
        uint256 isCoFounder; // 是否是联合创始人，1是，0否

        // uint256 hasWithdrawProfitWheelNum; // 8%的收益：开始提现的轮数(eg:如果为2，则从第3轮开始计算余额)
        // uint256 hasWithdrawProfitPeriodNum; // 8%的收益：开始提现的期数(eg:如果为2，则从第3期开始计算余额)
        // uint256 hasWithdrawRewardWheelNum; // 奖励(直推、间推、社区)：开始提现的轮数(eg:如果为2，则从第3轮开始计算余额)
        // uint256 hasWithdrawRewardPeriodNum; // 奖励(直推、间推、社区)：开始提现的期数(eg:如果为2，则从第3期开始计算余额)

        uint256 hasWithdrawTop10Amount; // 已经提取的Top10奖励
        uint256 hasWithdrawTop100Amount; // 已经提取的Top100奖励
        uint256 hasWithdrawAmount; // 已经提取的总收益（静态+直推+间推+社区）

        uint256 hasWithdrawWaxpDiviAAmount; // 已经提取的持有WAXP的分红
    }

    ////////////////////// 每轮的参与用户信息 //////////////////////////////////
    mapping(uint256 => mapping(address => WheelUserInfo)) public wheelUserInfoMap; // wheelNum => address => WheelUserInfo
    struct WheelUserInfo {
        uint256 hasWithdrawProfitPeriodNum; // 8%的收益：开始提现的期数(eg:如果为2，则从第3期开始计算余额)
        uint256 hasWithdrawRewardPeriodNum; // 奖励(直推、间推、社区)：开始提现的期数(eg:如果为2，则从第3期开始计算余额)

        // 每轮结束后，损失超过1200个WIKI的用户，损失的WIKI按照1080天线性释放，释放开始的区块高度为该轮的结束区块高度
        uint256 lastBlockNumberLock;
        uint256 hasWithdrawLockAmount;
    }

    ////////////////////// 每期的参与用户信息 //////////////////////////////////
    // eg: 第3期众筹满后会发放第1期参与用户的静态收益和动态奖励
    mapping(uint256 => mapping(uint256 => mapping(address => PeriodUserInfo))) public periodUserInfoMap; // wheelNum => periodNum => address => PeriodUserInfo
    struct PeriodUserInfo {
        uint256 amount; // 本期参与众筹的A币数量
        uint256 directPushReward; // 直推奖
        uint256 indirectAward; // 间推奖
        uint256 vipReward; // 社区(VIP)奖
    }

    ////////////////////// 每轮的Top10和Top100奖励，由外部计算后更新 //////////////////////////////////
    mapping(uint256 => address[]) public top10s; // wheelNum => Top10中奖者的地址数组
    mapping(uint256 => mapping(address => uint256)) public top10Map; // wheelNum => (Top10中奖者地址 => 中奖金额)
    mapping(uint256 => address[]) public top100s; // wheelNum => Top100中奖者的地址数组
    mapping(uint256 => mapping(address => uint256)) public top100Map; // wheelNum => (Top100中奖者地址 => 中奖金额)

    
    // 2%流入亏损Top10奖励池，3%流入持有WAXP奖励池，剩下的由项目方收走
    mapping(uint256 => uint256) public top10PoolTotalMap; // wheel => amount
    mapping(uint256 => mapping(uint256 => uint256)) public waxpPoolTotalMap; // wheel => period => amount

    event Buy(address _user, address _refer, uint256 _amount, uint256 _curWheelNum, uint256 _periodNum);
    event WithdrawStaticProfit(address _user, uint256 _pending);
    event WithdrawReward(address _user, uint256 _pending);
    event WithdrawTop10(address _user, uint256 _pending);
    event WithdrawTop100(address _user, uint256 _pending);
    event AddWheel(address _msgSender, uint256 wheelNum, uint256 _startTime, uint256 _amount);
    event UpdateVipLevel(address _msgSender, address _user, uint256 _vipLevel);
    event UpdateCoFounder(address _msgSender, address _user, uint256 _isCoFounder);
    event UpdateTop10(address _msgSender, uint256 _wheelNum, address[] _users, uint256[] _rewards);
    event UpdateTop100(address _msgSender, uint256 _wheelNum, address[] _users);
    event Settle(address _msgSender, uint256 _wheelNum);
    event WithdrawLockProfit(address _user, uint256 _pending);
    event WithdrawWaxpDivi(address _user, uint256 _pending);
    
    constructor(IERC20 _wiki, IERC20 _bzzone, IERC20 _nft, IERC20 _waxp, IERC20 _matebok, 
        address _teamer, address _canCaller) {
        wiki = _wiki;
        bzzone = _bzzone;
        nft = _nft;
        waxp = _waxp;
        matebok = _matebok;
        teamer = _teamer;
        canCaller = _canCaller;
        operator[msg.sender] = true;
    }

    /*
    参与众筹
    */
    function buy(address _refer, uint256 _amount, uint256 _curWheelNum) public {
        address _user = _msgSender();
        require(_user != _refer, "refer can not be Own");
        // 调用者地址上必须拥有10枚Bzzone(B币)和100枚WIKI(A币)
        require(bzzone.balanceOf(_user) >= 10e18, "Must have 10 Bzzone");
        require(wiki.balanceOf(_user) >= 100e18, "Must have 100 WIKI");
        uint256 _periodNum = wheelInfoMap[_curWheelNum].periodNum;
        _canBuy(_user, _amount, _curWheelNum, _periodNum);
        _bind(_user, _refer, _amount);
        // 资金分配
        wiki.safeTransferFrom(_user, teamer, _amount);
        waxpPoolTotalMap[_curWheelNum][_periodNum] = waxpPoolTotalMap[_curWheelNum][_periodNum].add(_amount.mul(3).div(100));
        top10PoolTotalMap[_curWheelNum] = top10PoolTotalMap[_curWheelNum].add(_amount.mul(2).div(100));
        // 保存个人用户信息
        UserInfo storage user = userInfoMap[_user];
        // user.amount = user.amount.add(_amount);
        periodUserInfoMap[_curWheelNum][_periodNum][_user].amount = _amount;
        // 保存当期信息
        periodInfoMap[_curWheelNum][_periodNum].hasBuyAmount = periodInfoMap[_curWheelNum][_periodNum].hasBuyAmount.add(_amount);
        periodInfoMap[_curWheelNum][_periodNum].users.push(_user);
        // 计算上级直推奖和间推奖
        _refer = userInfoMap[_user].refer;
        _calReferReward(_refer, _amount, _curWheelNum, _periodNum);
        // 计算社区奖
        _calVipReward(_user, _amount, _curWheelNum, _periodNum, 0, user.vipLevel, _amount.div(100));
        // 计算自己能否拿间推奖
        if (user.amount >= 100e18) {
            if (user.canIndirect == 0) {
                if (directPushsLength(_user) >= 3) {
                    address[] memory _addrs = directPushs(_user);
                    uint256 _count = 0;
                    for (uint256 i = 0; i < _addrs.length; i++) {
                        if (userInfoMap[_addrs[i]].amount >= 100e18) {
                            // 是有效用户
                            _count++;
                            if (_count == 3) {
                                user.canIndirect = 1;
                                break;
                            }
                        }
                    }
                }
            }
        }
        emit Buy(_user, _refer, _amount, _curWheelNum, _periodNum);
    }

    // 计算社区奖
    function _calVipReward(address _user, uint256 _amountOld, uint256 _curWheelNum, uint256 _periodNum, 
        uint256 _sameLevelComputeCount, uint256 _biggestVipLevel, uint256 _income) internal {
        for (uint256 i = 1; i <= 50; i++) {
            address _refer = userInfoMap[_user].refer;
            UserInfo memory referInfo = userInfoMap[_refer];
            uint256 _amount = referInfo.amount;
            if (_amount == 0) {
                return;
            }
            if (_amount >= 100e18) {
                uint256 _referVipLevel = referInfo.vipLevel;
                if (referInfo.isCoFounder == 1) {
                    _referVipLevel = 9;
                }
                if (_referVipLevel > 0) {
                    if (_referVipLevel == _biggestVipLevel) {
                        if (_sameLevelComputeCount == 0) {
                            if (_canGetReward(_refer, userInfoMap[_refer].isCoFounder, userInfoMap[_refer].vipLevel)) {
                                periodUserInfoMap[_curWheelNum][_periodNum][_refer].vipReward = 
                                periodUserInfoMap[_curWheelNum][_periodNum][_refer].vipReward.add(_income.div(10));
                            }
                            _sameLevelComputeCount = 1;
                        }
                    } else if (_referVipLevel > _biggestVipLevel) {
                        uint256 _diff = _referVipLevel.sub(_biggestVipLevel);
                        _income = _amountOld.mul(_diff).div(100);
                        if (_canGetReward(_refer, userInfoMap[_refer].isCoFounder, userInfoMap[_refer].vipLevel)) {
                            periodUserInfoMap[_curWheelNum][_periodNum][_refer].vipReward = 
                            periodUserInfoMap[_curWheelNum][_periodNum][_refer].vipReward.add(_income);
                        }
                        _sameLevelComputeCount = 0;
                        _biggestVipLevel = _referVipLevel;
                    }
                }
            }
            _user = _refer;
        }
    }

    // 获取推荐人应该获得的级差节点奖
    /*function _getDiffNodeAwardAmt(uint256 _referVipLevel, uint256 _biggestVipLevel, uint256 _amountOld)
        internal pure returns (uint256) {
        uint256 _diff = _referVipLevel.sub(_biggestVipLevel);
        return _amountOld.mul(_diff).div(100);
    }*/

    // 计算上级直推奖和间推奖
    function _calReferReward(address _refer, uint256 _amount, uint256 _curWheelNum, uint256 _periodNum) internal {
        if (userInfoMap[_refer].amount == 0) {
            return;
        }
        if (userInfoMap[_refer].amount >= 100e18) {
            if (_canGetReward(_refer, userInfoMap[_refer].isCoFounder, userInfoMap[_refer].vipLevel)) {
                periodUserInfoMap[_curWheelNum][_periodNum][_refer].directPushReward = 
                periodUserInfoMap[_curWheelNum][_periodNum][_refer].directPushReward.add(_amount.div(100));
            }
        }
        address _indirecter = userInfoMap[_refer].refer;
        if (userInfoMap[_indirecter].canIndirect == 1) {
            if (_canGetReward(_indirecter, userInfoMap[_indirecter].isCoFounder, userInfoMap[_indirecter].vipLevel)) {
                periodUserInfoMap[_curWheelNum][_periodNum][_indirecter].indirectAward = 
                periodUserInfoMap[_curWheelNum][_periodNum][_indirecter].indirectAward.add(_amount.div(200));
            }
        }
    }

    // v2以上级别的用户（不包括联创节点）需要持有200个WIKI才能获取奖励
    function _canGetReward(address _user, uint256 _isCoFounder, uint256 _vipLevel) view internal returns (bool _flag) {
        if (_isCoFounder == 1) {
            _flag = true;
        } else {
            if (_vipLevel <= 1) {
                _flag = true;
            } else {
                if (wiki.balanceOf(_user) >= 200e18) {
                    _flag = true;
                }
            }
        }
    }

    // 判断时间和输入金额
    function _canBuy(address _user, uint256 _amount, uint256 _curWheelNum, uint256 _periodNum) view internal {
        require(_curWheelNum <= wheelNum, "buy: _curWheelNum is error");
        require(wheelInfoMap[_curWheelNum].isEnd == 0, "buy: The current round is over");
        require(_amount > 0, "buy: _amount must be greater than 0");
        require(_amount % 1e18 == 0, "_amount must be an integer");  // 投资额只能为整数，以1个A币为单位
        require(periodUserInfoMap[_curWheelNum][_periodNum][_user].amount == 0, "buy: only buy once");

        PeriodInfo memory periodInfo = periodInfoMap[_curWheelNum][_periodNum];
        uint256 _startTime = periodInfo.startTime;
        uint256 _maxEndTime = _startTime.add(CONTINUED_OF_EACH_PERIOD);
        require(block.timestamp >= _startTime && block.timestamp <= _maxEndTime, "buy: Not within the crowdfunding time");

        // 获取当期每个用户能够购买的最小和最大额度
        (uint256 _min, uint256 _max) = _minAndMaXAmountByPeriod(_periodNum);
        // 获取当期剩余购买金额
        uint256 _remaningPeriod = periodInfo.amount.sub(periodInfo.hasBuyAmount);
        require(_remaningPeriod > 0, "No credit remaining");
        // 如果当期剩余购买金额小于当期每个用户的最小购买金额，则此次用户只能购买当期剩余购买金额
        if (_remaningPeriod <= _min) {
            require(_amount == _remaningPeriod, "buy: _amount is error 1");
        } else {
            if (_remaningPeriod < _max) {
                _max = _remaningPeriod;
            }
            require(_amount >= _min && _amount <= _max, "buy: _amount is error 2");
        }
    }

    // 获取当期每个用户能够购买的最小和最大额度
    function _minAndMaXAmountByPeriod(uint256 _period) public pure returns (uint256 _minPeriod, uint256 _maxPeriod) {
        _minPeriod = 10e18;
        _maxPeriod = getMaxUserCanBuy(_period);
    }
    function getMaxUserCanBuy(uint256 _periodNum) pure public returns(uint256 numOut) {
        if (_periodNum > 0) {
            uint256 periodNumMod = _periodNum - 1;
            uint256 remain = periodNumMod / 10;
            uint256 num = 1 << remain;
            uint256 increase = num * 10;
            uint256 increas2 = increase * 10;
            // TODO
            // uint256 base = 40;
            uint256 base = 40000;
            uint256 mod = _periodNum % 10;
            if (mod == 0) {
                mod = 10;
            }
            
            base = base + increas2 - 100;
            numOut = base + increase * mod;
            numOut = numOut.mul(1e18);
        }
    }

    // 绑定用户关系以及计算上级用户是否能拿间推奖
    function _bind(address _user, address _refer, uint256 _amount) internal {
        if (userInfoMap[_user].amount == 0) {
            // new user
            userCount++;
            userCountmap[userCount] = _user;
            if (userInfoMap[_refer].amount > 0) { // 邀请人存在
                userInfoMap[_user].refer = _refer;
                userInfoMap[_refer].directPushs.push(_user);
            }
        }
        userInfoMap[_user].amount = userInfoMap[_user].amount.add(_amount);
        _refer = userInfoMap[_user].refer;
        UserInfo storage referInfo = userInfoMap[_refer];
        // 邀请人是有效用户，计算邀请人能否拿间推奖
        if (referInfo.amount >= 100e18) {
            if (referInfo.canIndirect == 0) {
                if (directPushsLength(_refer) >= 3) {
                    address[] memory _addrs = directPushs(_refer);
                    uint256 _count = 0;
                    for (uint256 i = 0; i < _addrs.length; i++) {
                        if (userInfoMap[_addrs[i]].amount >= 100e18) {
                            // 是有效用户
                            _count++;
                            if (_count == 3) {
                                referInfo.canIndirect = 1;
                                return;
                            }
                        }
                    }
                }
            }
        }
    }

    // 待提取的静态收益
    function pendingStaticProfit(address _user) public view returns (uint256) {
        uint256 _wheelNum = wheelNum;
        if (_wheelNum == 0) {
            return 0;
        }
        if (userInfoMap[_user].amount == 0) {
            return 0;
        }
        uint256 _pending = 0;
        for (uint256 i = 1; i <= _wheelNum; i++) {
            uint256 _curPeriod = wheelInfoMap[i].periodNum;
            uint256 _userPeriod = wheelUserInfoMap[i][_user].hasWithdrawProfitPeriodNum;
            if (wheelInfoMap[i].isEnd == 0) {
                // 当轮未结束
                if (_curPeriod >= 4) {
                    for (uint256 j = _userPeriod + 1; j <= _curPeriod - 3; j++) {
                        uint256 _amount = periodUserInfoMap[i][j][_user].amount;
                        _pending = _pending.add(_amount.mul(108).div(100));
                    }
                }
            } else { 
                // 当轮已结束
                if (_curPeriod >= 4) {

                    for (uint256 j = _userPeriod + 1; j <= _curPeriod - 3; j++) {
                        uint256 _amount = periodUserInfoMap[i][j][_user].amount;
                        _pending = _pending.add(_amount.mul(108).div(100));
                    }
                    if (_userPeriod + 1 <= _curPeriod) {
                        // 倒数第一期原路返回，到时第2,3期返回50%
                        uint256 _amount1 = periodUserInfoMap[i][_curPeriod][_user].amount;
                        _pending = _pending.add(_amount1);
                        uint256 _amount2 = periodUserInfoMap[i][_curPeriod - 1][_user].amount;
                        _pending = _pending.add(_amount2.div(2));
                        uint256 _amount3 = periodUserInfoMap[i][_curPeriod - 2][_user].amount;
                        _pending = _pending.add(_amount3.div(2));
                    }

                } else {

                    if (_userPeriod + 1 <= _curPeriod) {
                        // 倒数第一期原路返回，到时第2,3期返回50%
                        uint256 _amount1 = periodUserInfoMap[i][_curPeriod][_user].amount;
                        _pending = _pending.add(_amount1);
                        if (_curPeriod >= 2) {
                            uint256 _amount2 = periodUserInfoMap[i][_curPeriod - 1][_user].amount;
                            _pending = _pending.add(_amount2.div(2));
                        }
                        if (_curPeriod >= 3) {
                            uint256 _amount3 = periodUserInfoMap[i][_curPeriod - 2][_user].amount;
                            _pending = _pending.add(_amount3.div(2));
                        }
                    }

                }
            }
        }
        return _pending;
    }

    // 提现静态收益
    function withdrawStaticProfit() public {
        uint256 _wheelNum = wheelNum;
        require(_wheelNum >= 1, "The game has not started");
        address _user = _msgSender();
        require(userInfoMap[_user].amount > 0, "No profit");
        uint256 _pending = 0;
        for (uint256 i = 1; i <= _wheelNum; i++) {
            uint256 _curPeriod = wheelInfoMap[i].periodNum;
            WheelUserInfo storage wheelUser = wheelUserInfoMap[i][_user];
            uint256 _userPeriod = wheelUser.hasWithdrawProfitPeriodNum;
            if (wheelInfoMap[i].isEnd == 0) {
                // 当轮未结束
                if (_curPeriod >= 4) {
                    for (uint256 j = _userPeriod + 1; j <= _curPeriod - 3; j++) {
                        uint256 _amount = periodUserInfoMap[i][j][_user].amount;
                        _pending = _pending.add(_amount.mul(108).div(100));
                    }
                    wheelUser.hasWithdrawProfitPeriodNum = _curPeriod - 3;
                }
            } else {
                // 当轮已结束
                if (_curPeriod >= 4) {

                    for (uint256 j = _userPeriod + 1; j <= _curPeriod - 3; j++) {
                        uint256 _amount = periodUserInfoMap[i][j][_user].amount;
                        _pending = _pending.add(_amount.mul(108).div(100));
                    }
                    if (_userPeriod + 1 <= _curPeriod) {
                        // 倒数第一期原路返回，到时第2,3期返回50%
                        uint256 _amount1 = periodUserInfoMap[i][_curPeriod][_user].amount;
                        _pending = _pending.add(_amount1);
                        uint256 _amount2 = periodUserInfoMap[i][_curPeriod - 1][_user].amount;
                        _pending = _pending.add(_amount2.div(2));
                        uint256 _amount3 = periodUserInfoMap[i][_curPeriod - 2][_user].amount;
                        _pending = _pending.add(_amount3.div(2));
                    }

                } else {

                    if (_userPeriod + 1 <= _curPeriod) {
                        // 倒数第一期原路返回，到时第2,3期返回50%
                        uint256 _amount1 = periodUserInfoMap[i][_curPeriod][_user].amount;
                        _pending = _pending.add(_amount1);
                        if (_curPeriod >= 2) {
                            uint256 _amount2 = periodUserInfoMap[i][_curPeriod - 1][_user].amount;
                            _pending = _pending.add(_amount2.div(2));
                        }
                        if (_curPeriod >= 3) {
                            uint256 _amount3 = periodUserInfoMap[i][_curPeriod - 2][_user].amount;
                            _pending = _pending.add(_amount3.div(2));
                        }
                    }

                }
                wheelUser.hasWithdrawProfitPeriodNum = _curPeriod;
            }
        }
        require(_pending > 0, "no static profit");
        require(wiki.balanceOf(address(this)) >= _pending, "withdrawStaticProfit: WIKI Insufficient balance");
        userInfoMap[_user].hasWithdrawAmount = userInfoMap[_user].hasWithdrawAmount.add(_pending);
        bzzone.safeTransferFrom(_user, teamer, withdrawFee);
        wiki.safeTransfer(_user, _pending);
        emit WithdrawStaticProfit(_user, _pending);
    }

    // 待提取的推荐奖励（直推 + 间推）
    function pendingReferReward(address _user) public view returns (uint256) {
        uint256 _wheelNum = wheelNum;
        if (_wheelNum == 0) {
            return 0;
        }
        if (userInfoMap[_user].amount == 0) {
            return 0;
        }
        uint256 _pending = 0;
        for (uint256 i = 1; i <= _wheelNum; i++) {
            uint256 _curPeriod = wheelInfoMap[i].periodNum;
            uint256 _userPeriod = wheelUserInfoMap[i][_user].hasWithdrawRewardPeriodNum;
            if (wheelInfoMap[i].isEnd == 0) {
                // 当轮未结束
                if (_curPeriod >= 4) {
                    for (uint256 j = _userPeriod + 1; j <= _curPeriod - 3; j++) {
                        uint256 _directPushReward = periodUserInfoMap[i][j][_user].directPushReward;
                        _pending = _pending.add(_directPushReward);
                        uint256 _indirectAward = periodUserInfoMap[i][j][_user].indirectAward;
                        _pending = _pending.add(_indirectAward);
                    }
                }
            } else { 
                // 当轮已结束，倒数第1期的奖励不发
                if (_curPeriod >= 4) {
                    for (uint256 j = _userPeriod + 1; j <= _curPeriod - 1; j++) {
                        uint256 _directPushReward = periodUserInfoMap[i][j][_user].directPushReward;
                        _pending = _pending.add(_directPushReward);
                        uint256 _indirectAward = periodUserInfoMap[i][j][_user].indirectAward;
                        _pending = _pending.add(_indirectAward);
                    }
                } else {
                    if (_userPeriod + 1 <= _curPeriod) {
                        if (_curPeriod >= 2) {
                            uint256 _directPushReward = periodUserInfoMap[i][_curPeriod - 1][_user].directPushReward;
                            _pending = _pending.add(_directPushReward);
                            uint256 _indirectAward = periodUserInfoMap[i][_curPeriod - 1][_user].indirectAward;
                            _pending = _pending.add(_indirectAward);
                        }
                        if (_curPeriod >= 3) {
                            uint256 _directPushReward = periodUserInfoMap[i][_curPeriod - 2][_user].directPushReward;
                            _pending = _pending.add(_directPushReward);
                            uint256 _indirectAward = periodUserInfoMap[i][_curPeriod - 2][_user].indirectAward;
                            _pending = _pending.add(_indirectAward);
                        }
                    }
                }
            }
        }
        return _pending;
    }

    // 待提取的社区奖励
    function pendingVipReward(address _user) public view returns (uint256) {
        uint256 _wheelNum = wheelNum;
        if (_wheelNum == 0) {
            return 0;
        }
        if (userInfoMap[_user].amount == 0) {
            return 0;
        }
        uint256 _pending = 0;
        for (uint256 i = 1; i <= _wheelNum; i++) {
            uint256 _curPeriod = wheelInfoMap[i].periodNum;
            uint256 _userPeriod = wheelUserInfoMap[i][_user].hasWithdrawRewardPeriodNum;
            if (wheelInfoMap[i].isEnd == 0) {
                // 当轮未结束
                if (_curPeriod >= 4) {
                    for (uint256 j = _userPeriod + 1; j <= _curPeriod - 3; j++) {
                        uint256 _vipReward = periodUserInfoMap[i][j][_user].vipReward;
                        _pending = _pending.add(_vipReward);
                    }
                }
            } else { 
                // 当轮已结束，倒数第1期的奖励不发
                if (_curPeriod >= 4) {
                    for (uint256 j = _userPeriod + 1; j <= _curPeriod - 1; j++) {
                        uint256 _vipReward = periodUserInfoMap[i][j][_user].vipReward;
                        _pending = _pending.add(_vipReward);
                    }
                } else {
                    if (_userPeriod + 1 <= _curPeriod) {
                        if (_curPeriod >= 2) {
                            uint256 _vipReward = periodUserInfoMap[i][_curPeriod - 1][_user].vipReward;
                            _pending = _pending.add(_vipReward);
                        }
                        if (_curPeriod >= 3) {
                            uint256 _vipReward = periodUserInfoMap[i][_curPeriod - 2][_user].vipReward;
                            _pending = _pending.add(_vipReward);
                        }
                    }
                }
            }
        }
        return _pending;
    }

    // 提现奖励（直推+间推+社区）
    function withdrawReward() public {
        uint256 _wheelNum = wheelNum;
        require(_wheelNum >= 1, "The game has not started");
        address _user = _msgSender();
        require(userInfoMap[_user].amount > 0, "No reward");
        uint256 _pending = 0;
        for (uint256 i = 1; i <= _wheelNum; i++) {
            uint256 _curPeriod = wheelInfoMap[i].periodNum;
            WheelUserInfo storage wheelUser = wheelUserInfoMap[i][_user];
            uint256 _userPeriod = wheelUser.hasWithdrawRewardPeriodNum;
            if (wheelInfoMap[i].isEnd == 0) {
                // 当轮未结束
                if (_curPeriod >= 4) {
                    for (uint256 j = _userPeriod + 1; j <= _curPeriod - 3; j++) {
                        uint256 _directPushReward = periodUserInfoMap[i][j][_user].directPushReward;
                        _pending = _pending.add(_directPushReward);
                        uint256 _indirectAward = periodUserInfoMap[i][j][_user].indirectAward;
                        _pending = _pending.add(_indirectAward);
                        uint256 _vipReward = periodUserInfoMap[i][j][_user].vipReward;
                        _pending = _pending.add(_vipReward);
                    }
                    wheelUser.hasWithdrawRewardPeriodNum = _curPeriod - 3;
                }
            } else {
                // 当轮已结束
                if (_curPeriod >= 4) {

                    for (uint256 j = _userPeriod + 1; j <= _curPeriod - 3; j++) {
                        uint256 _directPushReward = periodUserInfoMap[i][j][_user].directPushReward;
                        _pending = _pending.add(_directPushReward);
                        uint256 _indirectAward = periodUserInfoMap[i][j][_user].indirectAward;
                        _pending = _pending.add(_indirectAward);
                        uint256 _vipReward = periodUserInfoMap[i][j][_user].vipReward;
                        _pending = _pending.add(_vipReward);
                    }
                    if (_userPeriod + 1 <= _curPeriod) {
                        // 倒数第一期不发放奖励
                        uint256 _directPushReward = periodUserInfoMap[i][_curPeriod - 1][_user].directPushReward;
                        _pending = _pending.add(_directPushReward);
                        uint256 _indirectAward = periodUserInfoMap[i][_curPeriod - 1][_user].indirectAward;
                        _pending = _pending.add(_indirectAward);
                        uint256 _vipReward = periodUserInfoMap[i][_curPeriod - 1][_user].vipReward;
                        _pending = _pending.add(_vipReward);


                        uint256 _directPushReward2 = periodUserInfoMap[i][_curPeriod - 2][_user].directPushReward;
                        _pending = _pending.add(_directPushReward2);
                        uint256 _indirectAward2 = periodUserInfoMap[i][_curPeriod - 2][_user].indirectAward;
                        _pending = _pending.add(_indirectAward2);
                        uint256 _vipReward2 = periodUserInfoMap[i][_curPeriod - 2][_user].vipReward;
                        _pending = _pending.add(_vipReward2);
                    }

                } else {

                    if (_userPeriod + 1 <= _curPeriod) {
                        // 倒数第一期不发放奖励
                        if (_curPeriod >= 2) {
                            uint256 _directPushReward = periodUserInfoMap[i][_curPeriod - 1][_user].directPushReward;
                            _pending = _pending.add(_directPushReward);
                            uint256 _indirectAward = periodUserInfoMap[i][_curPeriod - 1][_user].indirectAward;
                            _pending = _pending.add(_indirectAward);
                            uint256 _vipReward = periodUserInfoMap[i][_curPeriod - 1][_user].vipReward;
                            _pending = _pending.add(_vipReward);
                        }
                        if (_curPeriod >= 3) {
                            uint256 _directPushReward2 = periodUserInfoMap[i][_curPeriod - 2][_user].directPushReward;
                            _pending = _pending.add(_directPushReward2);
                            uint256 _indirectAward2 = periodUserInfoMap[i][_curPeriod - 2][_user].indirectAward;
                            _pending = _pending.add(_indirectAward2);
                            uint256 _vipReward2 = periodUserInfoMap[i][_curPeriod - 2][_user].vipReward;
                            _pending = _pending.add(_vipReward2);
                        }
                    }

                }
                wheelUser.hasWithdrawRewardPeriodNum = _curPeriod;
            }
        }
        require(_pending > 0, "no reward");
        require(wiki.balanceOf(address(this)) >= _pending, "withdrawReward: WIKI Insufficient balance");
        userInfoMap[_user].hasWithdrawAmount = userInfoMap[_user].hasWithdrawAmount.add(_pending);
        bzzone.safeTransferFrom(_user, teamer, withdrawFee);
        wiki.safeTransfer(_user, _pending);
        emit WithdrawReward(_user, _pending);
    }

    // 待提取的top10奖励
    function pendingTop10(address _user) public view returns (uint256) {
        uint256 _wheelNum = wheelNum;
        if (_wheelNum == 0) {
            return 0;
        }
        uint256 _total = 0;
        for (uint256 i = 1; i <= _wheelNum; i++) {
            _total = _total.add(top10Map[i][_user]);
        }
        uint256 _pending = 0;
        uint256 _hasWithdrawTop10Amount = userInfoMap[_user].hasWithdrawTop10Amount;
        if (_total < _hasWithdrawTop10Amount) {
            _pending = 0;
        } else {
            _pending = _total.sub(_hasWithdrawTop10Amount);
        }
        return _pending;
    }

    // 提现top10奖励
    function withdrawTop10() public {
        uint256 _wheelNum = wheelNum;
        require(_wheelNum >= 1, "The game has not started");
        address _user = _msgSender();
        uint256 _total = 0;
        for (uint256 i = 1; i <= _wheelNum; i++) {
            _total = _total.add(top10Map[i][_user]);
        }
        uint256 _pending = 0;
        uint256 _hasWithdrawTop10Amount = userInfoMap[_user].hasWithdrawTop10Amount;
        if (_total < _hasWithdrawTop10Amount) {
            _pending = 0;
        } else {
            _pending = _total.sub(_hasWithdrawTop10Amount);
        }
        require(_pending > 0, "no top10 reward");
        require(wiki.balanceOf(address(this)) >= _pending, "withdrawTop10: WIKI Insufficient balance");
        userInfoMap[_user].hasWithdrawTop10Amount = userInfoMap[_user].hasWithdrawTop10Amount.add(_pending);
        bzzone.safeTransferFrom(_user, teamer, withdrawFee);
        wiki.safeTransfer(_user, _pending);
        emit WithdrawTop10(_user, _pending);
    }

    // 待提取的top100奖励
    function pendingTop100(address _user) public view returns (uint256) {
        uint256 _wheelNum = wheelNum;
        if (_wheelNum == 0) {
            return 0;
        }
        uint256 _total = 0;
        for (uint256 i = 1; i <= _wheelNum; i++) {
            _total = _total.add(top100Map[i][_user]);
        }
        uint256 _pending = 0;
        uint256 _hasWithdrawTop100Amount = userInfoMap[_user].hasWithdrawTop100Amount;
        if (_total < _hasWithdrawTop100Amount) {
            _pending = 0;
        } else {
            _pending = _total.sub(_hasWithdrawTop100Amount);
        }
        return _pending;
    }

    // 提现top100奖励
    function withdrawTop100() public {
        uint256 _wheelNum = wheelNum;
        require(_wheelNum >= 1, "The game has not started");
        address _user = _msgSender();
        uint256 _total = 0;
        for (uint256 i = 1; i <= _wheelNum; i++) {
            _total = _total.add(top100Map[i][_user]);
        }
        uint256 _pending = 0;
        uint256 _hasWithdrawTop100Amount = userInfoMap[_user].hasWithdrawTop100Amount;
        if (_total < _hasWithdrawTop100Amount) {
            _pending = 0;
        } else {
            _pending = _total.sub(_hasWithdrawTop100Amount);
        }
        require(_pending > 0, "no top100 reward");
        require(nft.balanceOf(address(this)) >= _pending, "withdrawTop100: NFT Insufficient balance");
        userInfoMap[_user].hasWithdrawTop100Amount = userInfoMap[_user].hasWithdrawTop100Amount.add(_pending);
        bzzone.safeTransferFrom(_user, teamer, withdrawFee);
        nft.safeTransfer(_user, _pending);
        emit WithdrawTop100(_user, _pending);
    }

    // 待提取的锁仓收益（每轮结束后，损失超过1000个WIKI的用户，损失的WIKI按照1080天线性释放（释放另外一个币））
    function pendingLockProfit(address _user, uint256 _wheelNum) view public returns (uint256 _pending) {
        if (_wheelNum <= wheelNum) {
            if (wheelInfoMap[_wheelNum].isEnd == 1) {
                uint256 _lastPeriodNum = wheelInfoMap[_wheelNum].periodNum;
                if (_lastPeriodNum > 1) {
                    uint256 _amount = periodUserInfoMap[_wheelNum][_lastPeriodNum - 1][_user].amount;
                    if (_lastPeriodNum > 2) {
                        uint256 _amount2 = periodUserInfoMap[_wheelNum][_lastPeriodNum - 2][_user].amount;
                        _amount = _amount.add(_amount2);
                    }
                    uint256 _amountLock = _amount.div(2);
                    if (_amountLock >= 1000e18) {
                        uint256 _hasWithdrawLockAmount = wheelUserInfoMap[_wheelNum][_user].hasWithdrawLockAmount;
                        if (_amountLock > _hasWithdrawLockAmount) {
                            uint256 _lastBlockNumberLock = wheelUserInfoMap[_wheelNum][_user].lastBlockNumberLock;
                            if (_lastBlockNumberLock == 0 && wheelInfoMap[_wheelNum].endBlockNumber > 0) {
                                _lastBlockNumberLock = wheelInfoMap[_wheelNum].endBlockNumber;
                            }
                            if (_lastBlockNumberLock > 0) {
                                if (block.number > _lastBlockNumberLock) {
                                    uint256 _diff = block.number.sub(_lastBlockNumberLock);
                                    _pending = _amountLock.mul(_diff).div(1080*24*60*20);
                                    if (_pending.add(_hasWithdrawLockAmount) > _amountLock) {
                                        _pending = _pending.add(_hasWithdrawLockAmount).sub(_amountLock);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // 提取锁仓收益（每轮结束后，损失超过1000个WIKI的用户，损失的WIKI按照1080天线性释放（释放另外一个币））
    function withdrawLockProfit(uint256 _wheelNum) public {
        address _user = _msgSender();
        require(_wheelNum <= wheelNum, "_wheelNum is error");
        require(wheelInfoMap[_wheelNum].isEnd == 1, "this _wheelNum is not end");
        uint256 _lastPeriodNum = wheelInfoMap[_wheelNum].periodNum;
        require(_lastPeriodNum > 1, "no lock profit 1");
        uint256 _amount = periodUserInfoMap[_wheelNum][_lastPeriodNum - 1][_user].amount;
        if (_lastPeriodNum > 2) {
            uint256 _amount2 = periodUserInfoMap[_wheelNum][_lastPeriodNum - 2][_user].amount;
            _amount = _amount.add(_amount2);
        }
        uint256 _amountLock = _amount.div(2);
        require(_amountLock >= 1000e18, "no lock profit 2");
        uint256 _hasWithdrawLockAmount = wheelUserInfoMap[_wheelNum][_user].hasWithdrawLockAmount;
        require(_amountLock > _hasWithdrawLockAmount, "no lock profit 3");
        uint256 _lastBlockNumberLock = wheelUserInfoMap[_wheelNum][_user].lastBlockNumberLock;
        if (_lastBlockNumberLock == 0 && wheelInfoMap[_wheelNum].endBlockNumber > 0) {
            _lastBlockNumberLock = wheelInfoMap[_wheelNum].endBlockNumber;
        }
        require(_lastBlockNumberLock > 0, "withdrawLockProfit is error");
        uint256 _pending = 0;
        if (block.number > _lastBlockNumberLock) {
            uint256 _diff = block.number.sub(_lastBlockNumberLock);
            _pending = _amountLock.mul(_diff).div(1080*24*60*20);
            if (_pending.add(_hasWithdrawLockAmount) > _amountLock) {
                _pending = _pending.add(_hasWithdrawLockAmount).sub(_amountLock);
            }
        }
        require(_pending > 0, "no lock profit 4");
        require(matebok.balanceOf(address(this)) >= _pending, "withdrawLockProfit: matebok Insufficient balance");
        wheelUserInfoMap[_wheelNum][_user].hasWithdrawLockAmount = wheelUserInfoMap[_wheelNum][_user].hasWithdrawLockAmount.add(_pending);
        wheelUserInfoMap[_wheelNum][_user].lastBlockNumberLock = block.number;
        matebok.safeTransfer(_user, _pending);
        emit WithdrawLockProfit(_user, _pending);
    }

    // 待提取的持有WAXP的分红
    /*function pendingWaxpDivi(address _user) view public returns (uint256 _pending) {
        if (waxpPoolTotal > 0) {
            uint256 _waxpBalance = waxp.balanceOf(_user);
            if (_waxpBalance > 0) {
                uint256 _waxpTotal = waxp.totalSupply();
                uint256 _hasWithdrawWaxpDiviAAmount = userInfoMap[_user].hasWithdrawWaxpDiviAAmount;
                uint256 _divi = _waxpBalance.mul(waxpPoolTotal).div(_waxpTotal);
                if (_divi > _hasWithdrawWaxpDiviAAmount) {
                    _pending = _divi.sub(_hasWithdrawWaxpDiviAAmount);
                }
            }
        }
    }*/

    // 提取持有WAXP的分红
    /*function withdrawWaxpDivi() public {
        require(waxpPoolTotal > 0, "no Dividends 1");
        address _user = _msgSender();
        uint256 _waxpBalance = waxp.balanceOf(_user);
        require(_waxpBalance > 0, "no waxp balance");
        uint256 _waxpTotal = waxp.totalSupply();
        uint256 _hasWithdrawWaxpDiviAAmount = userInfoMap[_user].hasWithdrawWaxpDiviAAmount;
        uint256 _divi = _waxpBalance.mul(waxpPoolTotal).div(_waxpTotal);
        require(_divi > _hasWithdrawWaxpDiviAAmount, "no Dividends 2");
        uint256 _pending = _divi.sub(_hasWithdrawWaxpDiviAAmount);
        require(wiki.balanceOf(address(this)) >= _pending, "withdrawWaxpDivi: WIKI Insufficient balance");
        userInfoMap[_user].hasWithdrawWaxpDiviAAmount = userInfoMap[_user].hasWithdrawWaxpDiviAAmount.add(_pending);
        wiki.safeTransfer(_user, _pending);
        emit WithdrawWaxpDivi(_user, _pending);
    }*/


    
    //////////////////////////////////////////////// operator start ////////////////////////////////////////////////////////////
    /*
    新开一轮，轮数顺延
    _startTime: 当轮开始时间，也是当轮第一期的开始时间，如果传入值为1则表示当前时间，传入其它值则从传入时间开始
    _amount: 当轮第一期的众筹金额，传入的值不需要加精度，代码中会自动加（比如当期设置的众筹金额为1000个WIKI，则传入1000即可，只能传入整数）
    */
    function addWheel(uint256 _startTime, uint256 _amount) public onlyOperator {
        if (_startTime == 1) {
            _startTime = block.timestamp;
        }
        wheelNum++;
        uint256 _wheelNum = wheelNum;
        wheelInfoMap[_wheelNum] = WheelInfo({
            wheel : _wheelNum,
            startTime : _startTime,
            endTime : 0,
            endBlockNumber : 0,
            periodNum : 1,
            isEnd : 0,
            isSetTop10 : 0,
            isSetTop100 : 0
        });
        
        periodInfoMap[_wheelNum][1].period = 1;
        periodInfoMap[_wheelNum][1].startTime = _startTime;
        periodInfoMap[_wheelNum][1].amount = _amount.mul(1e18);
        emit AddWheel(_msgSender(), wheelNum, _startTime, _amount);
    }
    
     modifier onlyOperator() {
        require(operator[msg.sender], 'operator: caller is not the operator');
        _;
    }
    
    function addOperator(address _user) public onlyOwner {
        operator[_user] = true;
    }
    
    function removeOperator(address _user) public onlyOwner {
        operator[_user] = false;
    }
    //////////////////////////////////////////////// operator end ////////////////////////////////////////////////////////////
 
    
    // 修改vip等级
    function updateVipLevel(address _user, uint256 _vipLevel) public onlyCanCaller {
        if (_vipLevel >= 1 && _vipLevel <= 6) {
            if (_vipLevel > userInfoMap[_user].vipLevel) {
                userInfoMap[_user].vipLevel = _vipLevel;
                emit UpdateVipLevel(_msgSender(), _user, _vipLevel);
            }
        }
    }

    // 修改联创节点, _isCoFounder为1修改为联创节点，0取消联创节点
    function updateCoFounder(address _user, uint256 _isCoFounder) public onlyCanCaller {
        if (_isCoFounder == 1) {
            userInfoMap[_user].isCoFounder = 1;
        } else {
            userInfoMap[_user].isCoFounder = 0;
        }
        emit UpdateCoFounder(_msgSender(), _user, _isCoFounder);
    }

    // 设置该轮的top10奖励
    function updateTop10(uint256 _wheelNum, address[] memory _users, uint256[] memory _rewards) public onlyCanCaller {
        require(_wheelNum <= wheelNum, "updateTop10: _wheelNum is error");
        require(wheelInfoMap[_wheelNum].isEnd == 1, "updateTop10: The _wheelNum is not over");
        require(wheelInfoMap[_wheelNum].isSetTop10 == 0, "updateTop10: The _wheelNum Reward set");
        // TODO
        // require(_users.length == 10, "updateTop10: _users is error");
        require(_users.length == _rewards.length, "updateTop10: _users or _rewards is error");
        top10s[_wheelNum] = _users;
        for (uint256 i = 0; i < _users.length; i++) {
            top10Map[_wheelNum][_users[i]] = _rewards[i];
        }
        wheelInfoMap[_wheelNum].isSetTop10 = 1;
        emit UpdateTop10(_msgSender(), _wheelNum, _users, _rewards);
    }

    // 设置该轮的top100奖励
    function updateTop100(uint256 _wheelNum, address[] memory _users) public onlyCanCaller {
        require(_wheelNum <= wheelNum, "updateTop100: _wheelNum is error");
        require(wheelInfoMap[_wheelNum].isEnd == 1, "updateTop100: The _wheelNum is not over");
        require(wheelInfoMap[_wheelNum].isSetTop100 == 0, "updateTop100: The _wheelNum Reward set");
        require(_users.length > 0, "updateTop100: _users is error");
        // require(_users.length == _rewards.length, "_users or _rewards is error");
        top100s[_wheelNum] = _users;
        for (uint256 i = 0; i < _users.length; i++) {
            top100Map[_wheelNum][_users[i]] = 1e18;
        }
        wheelInfoMap[_wheelNum].isSetTop100 = 1;
        emit UpdateTop100(_msgSender(), _wheelNum, _users);
    }

    // 结算，外部调用
    function settle(uint256 _wheelNum) public {
        require(_wheelNum <= wheelNum, "settle: _wheelNum is error");
        WheelInfo storage wheelInfo = wheelInfoMap[_wheelNum];
        require(wheelInfo.isEnd == 0, "this _wheelNum is end");
        uint256 _periodNum = wheelInfo.periodNum;
        PeriodInfo storage periodInfo = periodInfoMap[_wheelNum][_periodNum];
        uint256 _curTime = block.timestamp;
        if (periodInfo.amount == periodInfo.hasBuyAmount && periodInfo.amount > 0) {
            // 已众筹满，结算后进入下一期
            periodInfo.endTime = _curTime;
            uint256 _newPeriodNum = _periodNum + 1;
            wheelInfo.periodNum = _newPeriodNum;
            periodInfoMap[_wheelNum][_newPeriodNum].period = _newPeriodNum;
            periodInfoMap[_wheelNum][_newPeriodNum].startTime = _curTime.add(INTERVAL_OF_EACH_PERIOD);
            uint256 currentMaxTemp1 = periodInfo.amount.div(1e18);
            uint256 currentMaxTemp2 = currentMaxTemp1.mul(125).div(100);
            uint256 currentMax = currentMaxTemp2.mul(1e18);
            periodInfoMap[_wheelNum][_newPeriodNum].amount = currentMax;
        } else {
            // 未众筹满，计算是否已经过了最大众筹时间
            uint256 _maxEndTime = periodInfo.startTime.add(CONTINUED_OF_EACH_PERIOD);
            if (_curTime >= _maxEndTime) {
                // 已超出当期的最大结束时间，结束这一轮
                wheelInfo.isEnd = 1;
                wheelInfo.endTime = _curTime;
                wheelInfo.endBlockNumber = block.number;
                periodInfo.endTime = _curTime;
            }
        }
        emit Settle(_msgSender(), _wheelNum);
    }
 
     modifier onlyCanCaller() {
        require(msg.sender == canCaller, 'canCaller: caller is not the canCaller');
        _;
    }
    
    function changeCanCaller(address _canCaller) public onlyOwner {
        canCaller = _canCaller;
    }
        
    function periodUsersLength(uint256 _wheelNum, uint256 _periodNum) view public returns (uint256) {
        return periodInfoMap[_wheelNum][_periodNum].users.length;
    }
    
    function periodUsers(uint256 _wheelNum, uint256 _periodNum) view public returns (address[] memory) {
        return periodInfoMap[_wheelNum][_periodNum].users;
    }

    function directPushsLength(address _user) view public returns (uint256) {
        return userInfoMap[_user].directPushs.length;
    }
    
    function directPushs(address _user) view public returns (address[] memory) {
        return userInfoMap[_user].directPushs;
    }

    function top10sArray(uint256 _wheelNum) view public returns (address[] memory) {
        return top10s[_wheelNum];
    }

    function top100sArray(uint256 _wheelNum) view public returns (address[] memory) {
        return top100s[_wheelNum];
    }
    
    function withdrawWikiOnlyOwner(uint256 _amount) public onlyOwner {
        wiki.safeTransfer(_msgSender(), _amount);
    }
    
    function withdrawNftOnlyOwner(uint256 _amount) public onlyOwner {
        nft.safeTransfer(_msgSender(), _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}