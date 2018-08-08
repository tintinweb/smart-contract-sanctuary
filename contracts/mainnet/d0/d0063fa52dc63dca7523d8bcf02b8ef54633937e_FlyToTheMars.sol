pragma solidity ^0.4.24;

/**
 *
 *
 * ,------. ,-----. ,--.   ,--. ,-----.     ,--.   ,--.,--.                                  ,--.   ,--.
 * |  .---&#39;&#39;  .-.  &#39;|   `.&#39;   |&#39;  .-.  &#39;    |  |   |  |`--&#39;,--,--, ,--,--,  ,---. ,--.--.    |   `.&#39;   | ,--,--.,--.--. ,---.
 * |  `--, |  | |  ||  |&#39;.&#39;|  ||  | |  |    |  |.&#39;.|  |,--.|      \|      \| .-. :|  .--&#39;    |  |&#39;.&#39;|  |&#39; ,-.  ||  .--&#39;(  .-&#39;
 * |  |`   &#39;  &#39;-&#39;  &#39;|  |   |  |&#39;  &#39;-&#39;  &#39;    |   ,&#39;.   ||  ||  ||  ||  ||  |\   --.|  |       |  |   |  |\ &#39;-&#39;  ||  |   .-&#39;  `)
 * `--&#39;     `-----&#39; `--&#39;   `--&#39; `-----&#39;     &#39;--&#39;   &#39;--&#39;`--&#39;`--&#39;&#39;--&#39;`--&#39;&#39;--&#39; `----&#39;`--&#39;       `--&#39;   `--&#39; `--`--&#39;`--&#39;   `----&#39;
 *
 *
 * 源码不是原创，但是经过了本人审核，不存在资金被超级管理员转走的可能性
 * master#fomowinner.com
 */

// 飞向火星事件
contract FlyToTheMarsEvents {

  // 第一阶段购买key事件
  event onFirStage
  (
    address indexed player,
    uint256 indexed rndNo,
    uint256 keys,
    uint256 eth,
    uint256 timeStamp
  );

  // 第二阶段成为赢家事件
  event onSecStage
  (
    address indexed player,
    uint256 indexed rndNo,
    uint256 eth,
    uint256 timeStamp
  );

  // 玩家提现事件
  event onWithdraw
  (
    address indexed player,
    uint256 indexed rndNo,
    uint256 eth,
    uint256 timeStamp
  );

  // 获奖事件
  event onAward
  (
    address indexed player,
    uint256 indexed rndNo,
    uint256 eth,
    uint256 timeStamp
  );
}

// 飞向火星主合约
contract FlyToTheMars is FlyToTheMarsEvents {

  using SafeMath for *;           // 导入数学函数
  using KeysCalc for uint256;     // 导入key计算

  //每轮游戏的数据结构
  struct Round {
    uint256 eth;        // eth总量
    uint256 keys;       // key总量
    uint256 startTime;  // 开始时间
    uint256 endTime;    // 结束时间
    address leader;     // 赢家
    uint256 lastPrice;  // 第二阶段的最近出价
    bool award;         // 已经结束
  }

  //玩家数据结构
  struct PlayerRound {
    uint256 eth;        // 玩家已经花了多少eth
    uint256 keys;       // 玩家买到的key数量
    uint256 withdraw;   // 玩家已经提现的数量
  }

  uint256 public rndNo = 1;                                   // 当前游戏的轮数
  uint256 public totalEth = 0;                                // eth总量

  uint256 constant private rndFirStage_ = 12 hours;           // 第一轮倒计时长
  uint256 constant private rndSecStage_ = 12 hours;           // 第二轮倒计时长

  mapping(uint256 => Round) public round_m;                  // (rndNo => Round) 游戏存储机构
  mapping(uint256 => mapping(address => PlayerRound)) public playerRound_m;   // (rndNo => addr => PlayerRound) 玩家存储结构

  address public owner;               // 创建者地址
  uint256 public ownerWithdraw = 0;   // 创建者提走了多少eth

  //构造函数
  constructor()
    public
  {
    //发布合约设定第一轮游戏开始
    round_m[1].startTime = now;
    round_m[1].endTime = now + rndFirStage_;

    //所有人就是发布合约的人
    owner = msg.sender;
  }

  /**
   * 防止其他合约调用
   */
  modifier onlyHuman()
  {
    address _addr = msg.sender;
    uint256 _codeLength;

    assembly {_codeLength := extcodesize(_addr)}
    require(_codeLength == 0, "sorry humans only");
    _;
  }

  /**
   * 设置eth转入的边界
   */
  modifier isWithinLimits(uint256 _eth)
  {
    require(_eth >= 1000000000, "pocket lint: not a valid currency"); //最小8位小数金额
    require(_eth <= 100000000000000000000000, "no vitalik, no"); //最大10万eth
    _;
  }

  /**
   * 只有创建者能调用
   */
  modifier onlyOwner()
  {
    require(owner == msg.sender, "only owner can do it");
    _;
  }

  /**
   * 匿名函数
   * 自动接受汇款，实现购买key
   */
  function()
  onlyHuman()
  isWithinLimits(msg.value)
  public
  payable
  {
    uint256 _eth = msg.value;     //用户转入的eth量
    uint256 _now = now;           //现在时间
    uint256 _rndNo = rndNo;       //当前游戏轮数
    uint256 _ethUse = msg.value;  //用户可用来买key的eth数量

    // 是否要开启下一局
    if (_now > round_m[_rndNo].endTime)
    {
      _rndNo = _rndNo.add(1);     //开启新的一轮
      rndNo = _rndNo;

      round_m[_rndNo].startTime = _now;
      round_m[_rndNo].endTime = _now + rndFirStage_;
    }

    // 判断是否在第一阶段，从后面逻辑来看key不会超卖的
    if (round_m[_rndNo].keys < 10000000000000000000000000)
    {
      // 计算汇入的eth能买多少key
      uint256 _keys = (round_m[_rndNo].eth).keysRec(_eth);

      // key总量 10,000,000, 超过则进入下一个阶段
      if (_keys.add(round_m[_rndNo].keys) >= 10000000000000000000000000)
      {
        // 重新计算剩余key的总量
        _keys = (10000000000000000000000000).sub(round_m[_rndNo].keys);

        // 如果游戏第一阶段达到8562.5个eth那么就不能再买key了
        if (round_m[_rndNo].eth >= 8562500000000000000000)
        {
          _ethUse = 0;
        } else {
          _ethUse = (8562500000000000000000).sub(round_m[_rndNo].eth);
        }

        // 如果汇入的金额大于可以买的金额则退掉多余的部分
        if (_eth > _ethUse)
        {
          // 退款
          msg.sender.transfer(_eth.sub(_ethUse));
        } else {
          // fix
          _ethUse = _eth;
        }
      }

      // 至少要买1个key才会触发游戏规则，少于一个key不会成为赢家
      if (_keys >= 1000000000000000000)
      {
        round_m[_rndNo].endTime = _now + rndFirStage_;
        round_m[_rndNo].leader = msg.sender;
      }

      // 修改玩家数据
      playerRound_m[_rndNo][msg.sender].keys = _keys.add(playerRound_m[_rndNo][msg.sender].keys);
      playerRound_m[_rndNo][msg.sender].eth = _ethUse.add(playerRound_m[_rndNo][msg.sender].eth);

      // 修改这轮数据
      round_m[_rndNo].keys = _keys.add(round_m[_rndNo].keys);
      round_m[_rndNo].eth = _ethUse.add(round_m[_rndNo].eth);

      // 修改全局eth总量
      totalEth = _ethUse.add(totalEth);

      // 触发第一阶段成为赢家事件
      emit FlyToTheMarsEvents.onFirStage
      (
        msg.sender,
        _rndNo,
        _keys,
        _ethUse,
        _now
      );
    } else {
      // 第二阶段已经没有key了

      // lastPrice + 0.1Ether <= newPrice <= lastPrice + 10Ether
      // 新价格必须是在前一次出价+0.1到10eth之间
      uint256 _lastPrice = round_m[_rndNo].lastPrice;
      uint256 _maxPrice = (10000000000000000000).add(_lastPrice);

      // less than (lastPrice + 0.1Ether) ?
      // 出价必须大于最后一次出价至少0.1eth
      require(_eth >= (100000000000000000).add(_lastPrice), "Need more Ether");

      // more than (lastPrice + 10Ether) ?
      // 检查出价是否已经超过最后一次出价10eth
      if (_eth > _maxPrice)
      {
        _ethUse = _maxPrice;

        // 出价大于10eth部分自动退款
        msg.sender.transfer(_eth.sub(_ethUse));
      }

      // 更新这一局信息
      round_m[_rndNo].endTime = _now + rndSecStage_;
      round_m[_rndNo].leader = msg.sender;
      round_m[_rndNo].lastPrice = _ethUse;

      // 更新玩家信息
      playerRound_m[_rndNo][msg.sender].eth = _ethUse.add(playerRound_m[_rndNo][msg.sender].eth);

      // 更新这一局的eth总量
      round_m[_rndNo].eth = _ethUse.add(round_m[_rndNo].eth);

      // 更新全局eth总量
      totalEth = _ethUse.add(totalEth);

      // 触发第二阶段成为赢家事件
      emit FlyToTheMarsEvents.onSecStage
      (
        msg.sender,
        _rndNo,
        _ethUse,
        _now
      );
    }
  }

  /**
   * 根据游戏轮数提现
   */
  function withdrawByRndNo(uint256 _rndNo)
  onlyHuman()
  public
  {
    require(_rndNo <= rndNo, "You&#39;re running too fast");                      //别这么急，下一轮游戏再来领

    //计算60%能提现的量
    uint256 _total = (((round_m[_rndNo].eth).mul(playerRound_m[_rndNo][msg.sender].keys)).mul(60) / ((round_m[_rndNo].keys).mul(100)));
    uint256 _withdrawed = playerRound_m[_rndNo][msg.sender].withdraw;

    require(_total > _withdrawed, "No need to withdraw");                     //提完了就不要再提了

    uint256 _ethOut = _total.sub(_withdrawed);                                //计算本次真实能提数量
    playerRound_m[_rndNo][msg.sender].withdraw = _total;                      //记录下来，下次再想提就没门了

    msg.sender.transfer(_ethOut);                                             //说了这么多，转钱吧

    // 发送玩家提现事件
    emit FlyToTheMarsEvents.onWithdraw
    (
      msg.sender,
      _rndNo,
      _ethOut,
      now
    );
  }

  /**
   * 这个是要领大奖啊，指定游戏轮数
   */
  function awardByRndNo(uint256 _rndNo)
  onlyHuman()
  public
  {
    require(_rndNo <= rndNo, "You&#39;re running too fast");                        //别这么急，下一轮游戏再来领
    require(now > round_m[_rndNo].endTime, "Wait patiently");                   //还没结束呢，急什么急
    require(round_m[_rndNo].leader == msg.sender, "The prize is not yours");    //对不起，眼神不对
    require(round_m[_rndNo].award == false, "Can&#39;t get prizes repeatedly");     //你还想重复拿么？没门

    uint256 _ethOut = ((round_m[_rndNo].eth).mul(35) / (100));  //计算那一轮游戏中的35%的资金
    round_m[_rndNo].award = true;                               //标记已经领了，可不能重复领了
    msg.sender.transfer(_ethOut);                               //转账，接好了

    // 发送领大奖事件
    emit FlyToTheMarsEvents.onAward
    (
      msg.sender,
      _rndNo,
      _ethOut,
      now
    );
  }

  /**
   * 合约所有者提现，可分次提，最多为总资金盘5%
   * 任何人都可以执行，但是只有合约的所有人收到款
   */
  function feeWithdraw()
  onlyHuman()
  public
  {
    uint256 _total = (totalEth.mul(5) / (100));           //当前总量的5%
    uint256 _withdrawed = ownerWithdraw;                  //已经提走的数量

    require(_total > _withdrawed, "No need to withdraw"); //如果已经提走超过了量那么不能再提

    ownerWithdraw = _total;                               //更改所有者已经提走的量，因为合约方法本身都是事务保护的，所以先执行也没问题
    owner.transfer(_total.sub(_withdrawed));              //给合约所有者转账
  }

  /**
   * 更改合约所有者，只有合约创建者可以调用
   */
  function changeOwner(address newOwner)
  onlyOwner()
  public
  {
    owner = newOwner;
  }

  /**
   * 获取当前这轮游戏的信息
   *
   * @return round id
   * @return total eth for round
   * @return total keys for round
   * @return time round started
   * @return time round ends
   * @return current leader
   * @return lastest price
   * @return current key price
   */
  function getCurrentRoundInfo()
  public
  view
  returns (uint256, uint256, uint256, uint256, uint256, address, uint256, uint256)
  {

    uint256 _rndNo = rndNo;

    return (
    _rndNo,
    round_m[_rndNo].eth,
    round_m[_rndNo].keys,
    round_m[_rndNo].startTime,
    round_m[_rndNo].endTime,
    round_m[_rndNo].leader,
    round_m[_rndNo].lastPrice,
    getBuyPrice()
    );
  }

  /**
   * 获取这轮游戏的第一阶段的购买价格
   *
   * @return price for next key bought (in wei format)
   */
  function getBuyPrice()
  public
  view
  returns (uint256)
  {
    uint256 _rndNo = rndNo;
    uint256 _now = now;

    // start next round?
    if (_now > round_m[_rndNo].endTime)
    {
      return (75000000000000);
    }
    if (round_m[_rndNo].keys < 10000000000000000000000000)
    {
      return ((round_m[_rndNo].keys.add(1000000000000000000)).ethRec(1000000000000000000));
    }
    //second stage
    return (0);
  }
}

// key计算
library KeysCalc {

  //引入数学函数
  using SafeMath for *;

  /**
   * 计算收到一定eth时卖出的key数量
   *
   * @param _curEth current amount of eth in contract
   * @param _newEth eth being spent
   * @return amount of ticket purchased
   */
  function keysRec(uint256 _curEth, uint256 _newEth)
  internal
  pure
  returns (uint256)
  {
    return (keys((_curEth).add(_newEth)).sub(keys(_curEth)));
  }

  /**
   * 计算出售一定key时收到的eth数量
   *
   * @param _curKeys current amount of keys that exist
   * @param _sellKeys amount of keys you wish to sell
   * @return amount of eth received
   */
  function ethRec(uint256 _curKeys, uint256 _sellKeys)
  internal
  pure
  returns (uint256)
  {
    return ((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
  }

  /**
   * 计算一定数量的eth会兑换多少key
   *
   * @param _eth eth "in contract"
   * @return number of keys that would exist
   */
  function keys(uint256 _eth)
  internal
  pure
  returns (uint256)
  {
    return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000);
  }

  /**
   * 计算给定key数的情况下eth数量
   *
   * @param _keys number of keys "in contract"
   * @return eth that would exists
   */
  function eth(uint256 _keys)
  internal
  pure
  returns (uint256)
  {
    return ((78125000).mul(_keys.sq()).add(((149999843750000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
  }
}

/**
 * 数学函数库
 *
 * @dev Math operations with safety checks that throw on error
 * - added sqrt
 * - added sq
 * - added pwr 
 * - changed asserts to requires with error log outputs
 * - removed div, its useless
 */
library SafeMath {

  /**
  * 乘法
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
  * 减法
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
  * 加法
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
   * 平方根
   */
  function sqrt(uint256 x)
  internal
  pure
  returns (uint256 y)
  {
    uint256 z = ((add(x, 1)) / 2);
    y = x;
    while (z < y)
    {
      y = z;
      z = ((add((x / z), z)) / 2);
    }
  }

  /**
   * 平方
   */
  function sq(uint256 x)
  internal
  pure
  returns (uint256)
  {
    return (mul(x, x));
  }

  /**
   * 乘法递增
   */
  function pwr(uint256 x, uint256 y)
  internal
  pure
  returns (uint256)
  {
    if (x == 0)
      return (0);
    else if (y == 0)
      return (1);
    else
    {
      uint256 z = x;
      for (uint256 i = 1; i < y; i++)
        z = mul(z, x);
      return (z);
    }
  }
}