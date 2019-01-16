pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));

    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {

  event Pause();

  event Unpause();

  bool public paused = false;

  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused 
    returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused 
    returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}


// ERC20 Token
contract ERC20Token {

    function balanceOf(address _owner) constant public returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);
}

// 业务合约
contract DiceBaseBiz is Pausable {

  // Qian合约地址 
  address public qianContractAddress = 0x585C6Ad9FC293A2BF2f3C01DB15328Aa828ec10e;
  // 平台地址
  address public platformAddress = 0x1F7caD7C4a37B5B43CBf7b5608CDdD24fbf23bE5;
  // 平台手续费
  uint256 public serviceChargeRate = 5;
  // 平台维护费
  uint256 public maintenanceChargeRate = 0;
  // 单次上限
  uint256 public upperLimit = 1000 * 10 ** 18;
  // 单次下限
  uint256 public lowerLimit = 10 * 10 ** 18;

  ERC20Token QIAN;

  constructor() public {
      QIAN = ERC20Token(qianContractAddress);
  }

  /**
    骰子结果
   */
  struct Dice{
    uint256 startAt;
    uint8 result;
    uint8 odds;
    uint8 finished;
    uint8 abortived;
  }

  /**
    用户押注
   */
  struct Order{
    uint256 id;
    address member;
    uint256 bean;
    uint8 stake;
  }

  // 事件状态
  enum DiceStatus {
    // 进行中
    Progress,
    // 待公布
    Deadline,
    // 已结束
    Finished,
    // 流拍
    Abortive
  }

  //存储所有事件
  Dice[] public dices;

  // 存储投注订单
  mapping(uint256 => Order[]) orders;
  // 存储 总金额
  mapping(uint256 => uint256) beans;
  // 存储 买大或买小的金额
  mapping(uint256 => mapping(uint8 => uint256)) stakeBeans;



  // 创建
  event Create(uint256 indexed _id);

  // 投注
  event Deposit(uint256 indexed _id,address indexed depositer,uint8 indexed stake,uint256 bean);

  // 开奖
  event Publish(uint256 indexed _id,uint8 indexed _result,uint256 indexed odds);

  // 流拍 
  event Abortive(uint256 indexed _id);



  // 获取事件状态
  function getDiceStatus(uint256 _id) internal view returns(DiceStatus){
    Dice memory _dice = dices[_id];
    uint256 _time = now  + 30;

    if(_dice.abortived == 1){
      return DiceStatus.Abortive;
    }

    if(_dice.finished == 1){
      return DiceStatus.Finished;
    }
    
    if(_time < _dice.startAt){
      return DiceStatus.Progress;
    }

    if(_time >= _dice.startAt){
      return DiceStatus.Deadline;
    }
  }



  // 创建事件
  function create() public onlyOwner whenNotPaused returns(bool){
    uint256  _startAt  = now + 30; //创建时间 30秒后开始
    
    // 存储
    dices.push(Dice(_startAt,0,0,0,0));

    emit Create(dices.length -1);

    return true;
  }

  /**
    用户投注  
   */
  function deposit(uint256 _id,uint8 _stake, uint256 _bean) public whenNotPaused returns(bool) {
    require(dices[_id].startAt > 0,&#39;Dice not existed !!!&#39;);
    require(getDiceStatus(_id) == DiceStatus.Progress,&#39;Dice status must be Progressed !!!&#39;);

    // 存储用户订单
    Order[] storage _orders = orders[_id];
    _orders.push(Order(_id,msg.sender,_bean,_stake));

    // 存储投注金额
    beans[_id] += _bean;
    stakeBeans[_id][_stake] += _bean;

    //转账
    QIAN.transferFrom(msg.sender,address(this),_bean);

    emit Deposit(_id, msg.sender,_stake,_bean);

    return true;
  }


  /**
    流拍
   */
  function abortiv(uint256 _id) public onlyOwner whenNotPaused returns(bool){
    require(dices[_id].startAt > 0,&#39;Dice not existed !!!&#39;);

    // 流拍事件 不收手续费 直接返还资金
    if(beans[_id] == 0){
      return true;
    }

    // 转账
    Order[] memory _orders = orders[_id];
    for(uint256 i = 0; i < _orders.length; i++){
      QIAN.transferFrom(address(this),_orders[i].member,_orders[i].bean);
    }

    emit Abortive(_id);

    return true;
  }

  /**
    开奖
   */
  function publish(uint256 _id) public onlyOwner returns(bool) {
    require(dices[_id].startAt > 0,&#39;Dice not existed !!!&#39;);

    // 获得 总余额
    uint256 _beans = beans[_id];
    // 计算随机数，获得结果
    uint8 result = _generateRandom(_beans,_id);

    require(result > 0 && result <= 6,&#39;Result is not right !!!&#39;);

    uint8 _stake = 0;

    if(result > 3 ){
      // 开了小
      _stake = 1;
    }
    uint256  _stakeBeans = stakeBeans[_id][_stake];
    // 计算赔率
    uint256 odds = _beans * (100 - serviceChargeRate - maintenanceChargeRate ) / _stakeBeans;

    Order[] memory _orders = orders[_id];

    //收取手续费
    uint256 platformFee = _beans * (serviceChargeRate + maintenanceChargeRate) / 100;
    QIAN.transfer(platformAddress, platformFee);
    
    // 分账
    for (uint256 i = 0; i  < _orders.length; i++) {
        if(_orders[i].stake == _stake){
            QIAN.transfer(_orders[i].member,(_beans - platformFee) * _orders[i].bean/ _stakeBeans);
        }
    }
    
    emit Publish(_id,result,odds);

    return true;
  }

  // 计算随机数
  function _generateRandom(uint256 x,uint256 _id) private pure returns (uint8) {
      uint256 _rand = uint256(keccak256(bytes32(x + _id)));
      uint8 rand = uint8(keccak256(bytes32(_rand + x + _id)));
      return (rand % 6)  + 1;
  }

}



// 主合约
contract DiceContract is DiceBaseBiz {
 
    /**
     *  Recovery donated ether
     */
    function collectEtherBack(address collectorAddress) public onlyOwner {
        uint256 b = address(this).balance;
        require(b > 0);
        require(collectorAddress != 0x0);

        collectorAddress.transfer(b);
    }

    /**
    *  Recycle other ERC20 tokens
    */
    function collectOtherTokens(address tokenContract, address collectorAddress) onlyOwner public returns (bool) {
        ERC20Token t = ERC20Token(tokenContract);

        uint256 b = t.balanceOf(address(this));
        return t.transfer(collectorAddress, b);
    }

}