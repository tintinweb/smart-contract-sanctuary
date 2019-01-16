pragma solidity ^0.4.24;


contract Ownable {

  address public owner;
  
  mapping(address => uint8) public operators;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() 
    public {
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
   * @dev Throws if called by any account other than the operator
   */
  modifier onlyOperator() {
    require(operators[msg.sender] == uint8(1)); 
    _;
  }

  /**
   * @dev operator management
   */
  function operatorManager(address[] _operators,uint8 flag) 
    public 
    onlyOwner 
    returns(bool){
      for(uint8 i = 0; i< _operators.length; i++) {
        if(flag == uint8(0)){
          operators[_operators[i]] = 1;
        } else {
          delete operators[_operators[i]];
        }
      }
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) 
    public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
    emit OwnershipTransferred(owner, newOwner);
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


/**
 *  预测事件合约对象 
 *  @author linq <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="ecdddcddd4dcd9dfdddadaac9d9dc28f8381">[email&#160;protected]</a>>
 */
contract GuessBaseBiz is Pausable {
    
  // MOS合约地址 
  address public mosContractAddress = 0xbC668E5c79992Cc26C9B979dC10F397C3C816067;
  // 平台地址
  address public platformAddress = 0xe0F969610699f88612518930D88C0dAB39f67985;
  // 平台手续费
  uint256 public serviceChargeRate = 5;
  // 平台维护费
  uint256 public maintenanceChargeRate = 0;
  // 单次上限
  uint256 public upperLimit = 1000 * 10 ** 18;
  // 单次下限
  uint256 public lowerLimit = 1 * 10 ** 18;
  
  
  ERC20Token MOS;
  
  // =============================== Event ===============================
    
  // 创建预测事件成功后广播
  event CreateGuess(uint256 indexed id, address indexed creator);

//   直投事件
//   event Deposit(uint256 indexed id,address indexed participant,uint256 optionId,uint256 bean);

  // 代投事件  
  event DepositAgent(address indexed participant, uint256 indexed id, uint256 optionId, uint256 totalBean);

  // 公布选项事件 
  event PublishOption(uint256 indexed id, uint256 indexed optionId, uint256 odds);

  // 预测事件流拍事件
  event Abortive(uint256 indexed id);
  
  constructor() public {
      MOS = ERC20Token(mosContractAddress);
  }

  struct Guess {
    // 预测事件ID
    uint256 id;
    // 预测事件创建者
    address creator;
    // 预测标题
    string title;
    // 数据源名称+数据源链接
    string source;
    // 预测事件分类
    string category;
    // 是否下架 1.是 0.否
    uint8 disabled;
    // 预测事件描述
    bytes desc;
    // 开始时间
    uint256 startAt;
    // 封盘时间  
    uint256 endAt; 
    // 是否结束
    uint8 finished; 
    // 是否流拍
    uint8 abortive; 
    // 选项ID
    uint256[] optionIds;
    // 选项名称
    bytes32[] optionNames;
  }

//   // 订单
//   struct Order {
//     address user;
//     uint256 bean;
//   }

  // 平台代理订单
  struct AgentOrder {
    address participant;
    string ipfsBase58;
    string dataHash;
  }
  

  // 存储所有的预测事件
  mapping (uint256 => Guess) public guesses;

  // 存储所有用户直投订单
//   mapping (uint256 => mapping(uint256 => Order[])) public orders;

  // 通过预测事件ID和选项ID，存储该选项所有参与的地址
  mapping (uint256 => mapping (uint256 => AgentOrder[])) public agentOrders;
  
  // 存储事件总投注 
  mapping (uint256 => uint256) public guessTotalBean;
  
  // 存储某选项总投注 
  mapping (uint256 => uint256) public optionTotalBean;

  // 存储某选项某用户总投注 
  mapping (uint256 => mapping(address => uint256)) public userOptionTotalBean;

  /**
   * 预测事件状态
   */
  enum GuessStatus {
    // 未开始
    NotStarted, 
    // 进行中
    Progress,
    // 待公布
    Deadline,
    // 已结束
    Finished,
    // 流拍
    Abortive
  }

  // 判断是否为禁用状态
  function disabled(uint256 id) public view returns(bool) {
      if(guesses[id].disabled == 0){
          return false;
      }else {
          return true;
      }
  }

 /**
   * 获取预测事件状态
   * 
   * 未开始
   *     未到开始时间
   * 进行中
   *     在开始到结束时间范围内
   * 待公布/已截止
   *     已经过了结束时间，并且finished为0
   * 已结束
   *     已经过了结束时间，并且finished为1,abortive=0
   * 流拍
   *     abortive=1，并且finished为1 流拍。（退币）
   */
  function getGuessStatus(uint256 guessId) 
    internal 
    view
    returns(GuessStatus) {
      GuessStatus gs;
      Guess memory guess = guesses[guessId];
      uint256 _now = now; 
      if(guess.startAt > _now) {
        gs = GuessStatus.NotStarted;
      } else if((guess.startAt <= _now && _now <= guess.endAt)
                 && guess.finished == 0 
                 && guess.abortive == 0 ) {
        gs = GuessStatus.Progress;
      } else if(_now > guess.endAt && guess.finished == 0) {
        gs = GuessStatus.Deadline;
      } else if(_now > guess.endAt && guess.finished == 1 && guess.abortive == 0) {
        gs = GuessStatus.Finished;  
      } else if(guess.abortive == 1 && guess.finished == 1){
        gs = GuessStatus.Abortive; 
      }
    return gs;
  }
    
  function() public payable {
  }

  /**
   * 修改预测系统变量
   * @author linq
   */
  function modifyVariable
    (
        address _platformAddress, 
        uint256 _serviceChargeRate, 
        uint256 _maintenanceChargeRate,
        uint256 _upperLimit,
        uint256 _lowerLimit
    ) 
    public {
      platformAddress = _platformAddress;
      serviceChargeRate = _serviceChargeRate;
      maintenanceChargeRate = _maintenanceChargeRate;
      upperLimit = _upperLimit * 10 ** 18;
      lowerLimit = _lowerLimit * 10 ** 18;
  }
  
   // 创建预测事件
  function createGuess(
       uint256 _id, 
       string _title,
       string _source, 
       string _category,
       uint8 _disabled,
       bytes _desc, 
       uint256 _startAt, 
       uint256 _endAt,
       uint256[] _optionId, 
       bytes32[] _optionName
       ) 
       public 
       whenNotPaused {
    require(guesses[_id].id == uint256(0), "The current guess already exists !!!");
    require(_optionId.length == _optionName.length, "please check options !!!");
    
    guesses[_id] = Guess(_id,
          msg.sender,
          _title,
          _source,
          _category,
          _disabled,
          _desc,
          _startAt,
          _endAt,
          0,
          0,
          _optionId,
          _optionName
        );
    
    emit CreateGuess(_id, msg.sender);
  }


    /**
     * 审核|更新预测事件
     */
    function auditGuess
    (
        uint256 _id,
        string _title,
        uint8 _disabled,
        bytes _desc, 
        uint256 _endAt) 
        public 
        onlyOwner
    {
        require(guesses[_id].id != uint256(0), "The current guess not exists !!!");
        require(getGuessStatus(_id) == GuessStatus.NotStarted, "The guess cannot audit !!!");
        Guess storage guess = guesses[_id];
        guess.title = _title;
        guess.disabled = _disabled;
        guess.desc = _desc;
        guess.endAt = _endAt;
   }

  /**
   * 用户直接参与事件预测
   */ 
//   function deposit(uint256 id, uint256 optionId, uint256 bean) 
//     public
//     payable
//     whenNotPaused
//     returns (bool) {
//       require(!disabled(id), "The guess disabled!!!");
//       require(getGuessStatus(id) == GuessStatus.Progress, "The guess cannot participate !!!");
//       require(bean >= lowerLimit && bean <= upperLimit, "Bean quantity nonconformity!!!");
      
//       // 存储用户订单
//       Order memory order = Order(msg.sender, bean);
//       orders[id][optionId].push(order);
//       // 某用户订单该选项总投注数
//       userOptionTotalBean[optionId][msg.sender] += bean;
//       // 存储事件总投注
//       guessTotalBean[id] += bean;
//       MOS.transferFrom(msg.sender, address(this), bean);
    
//       emit Deposit(id, msg.sender, optionId, bean);
//       return true;
//   }

   /**
    * 平台代理用户参与事件预测
    */
  function depositAgent
  (
      uint256 id, 
      uint256 optionId, 
      string ipfsBase58,
      string dataHash,
      uint256 totalBean
  ) 
    public
    onlyOperator
    whenNotPaused
    returns (bool) {
    require(!disabled(id), "The guess disabled!!!");
    require(getGuessStatus(id) == GuessStatus.Deadline, "The guess cannot participate !!!");
    
    // 通过预测事件ID和选项ID，存储该选项所有参与的地址
    AgentOrder[] storage _agentOrders = agentOrders[id][optionId];
    
     AgentOrder memory agentOrder = AgentOrder(msg.sender,ipfsBase58,dataHash);
    _agentOrders.push(agentOrder);
   
    MOS.transferFrom(msg.sender, address(this), totalBean);
    
    // 某用户订单该选项总投注数
    userOptionTotalBean[optionId][msg.sender] += totalBean;
    // 订单选项总投注 
    optionTotalBean[optionId] += totalBean;
    // 存储事件总投注
    guessTotalBean[id] += totalBean;
    
    emit DepositAgent(msg.sender, id, optionId, totalBean);
    return true;
  }
  

    /**
     * 公布事件的结果
     */ 
    function publishOption(uint256 id, uint256 optionId) 
      public 
      onlyOwner
      whenNotPaused
      returns (bool) {
      require(!disabled(id), "The guess disabled!!!");
      require(getGuessStatus(id) == GuessStatus.Deadline, "The guess cannot publish !!!");
      Guess storage guess = guesses[id];
      guess.finished = 1;
      // 该预测时间总投注 
      uint256 totalBean = guessTotalBean[id];
      // 成功选项投注总数
      uint256 _optionTotalBean = optionTotalBean[optionId];
      // 判断是否低赔率事件
      uint256 odds = totalBean * (100 - serviceChargeRate - maintenanceChargeRate) / _optionTotalBean;
      
      AgentOrder[] memory _agentOrders = agentOrders[id][optionId];
      if(odds >= uint256(100)){
        // 平台收取手续费
        uint256 platformFee = totalBean * (serviceChargeRate + maintenanceChargeRate) / 100;
        MOS.transfer(platformAddress, platformFee);
        
        for(uint8 i = 0; i< _agentOrders.length; i++){
            MOS.transfer(_agentOrders[i].participant, (totalBean - platformFee) 
                        * userOptionTotalBean[optionId][_agentOrders[i].participant] 
                        / _optionTotalBean);
        }
      } else {
        // 低赔率事件，平台不收取手续费
        for(uint8 j = 0; j< _agentOrders.length; j++){
            MOS.transfer(_agentOrders[j].participant, totalBean
                        * userOptionTotalBean[optionId][_agentOrders[j].participant] 
                        / _optionTotalBean);
        }
      }

      emit PublishOption(id, optionId, odds);
      return true;
    }
    
    
    /**
     * 事件流拍
     */
    function abortive(uint256 id) 
        public 
        onlyOwner
        returns(bool) {
        require(getGuessStatus(id) == GuessStatus.Progress ||
                getGuessStatus(id) == GuessStatus.Deadline, "The guess cannot abortive !!!");
    
        Guess storage guess = guesses[id];
        guess.abortive = 1;
        guess.finished = 1;
        // 退回
        uint256[] memory options = guess.optionIds;
        
        for(uint8 i = 0; i< options.length;i ++){
            //代投退回
            AgentOrder[] memory _agentOrders = agentOrders[id][options[i]];
            for(uint8 j = 0; j < _agentOrders.length; j++){
                uint256 _optionTotalBean = userOptionTotalBean[options[i]][_agentOrders[j].participant];
                MOS.transfer(_agentOrders[j].participant, _optionTotalBean);
            }
        }
        emit Abortive(id);
        return true;
    }
    
    // /**
    //  * 获取事件投注总额 
    //  */ 
    // function guessTotalBeanOf(uint256 id) public view returns(uint256){
    //     return guessTotalBean[id];
    // }
    
    // /**
    //  * 获取事件选项代投订单信息
    //  */ 
    // function agentOrdersOf(uint256 id,uint256 optionId) 
    //     public 
    //     view 
    //     returns(
    //         address participant,
    //         address[] users,
    //         uint256[] beans
    //     ) {
    //     AgentOrder[] memory agentOrder = agentOrders[id][optionId];
    //     return (
    //         agentOrder.participant, 
    //         agentOrder.users, 
    //         agentOrder.beans
    //     );
    // }
    
    
    // /**
    //  * 获取用户直投订单 
    //  */ 
    // function ordersOf(uint256 id, uint256 optionId) public view 
    //     returns(address[] users,uint256[] beans){
    //     Order[] memory _orders = orders[id][optionId];
    //     address[] memory _users;
    //     uint256[] memory _beans;
        
    //     for (uint8 i = 0; i < _orders.length; i++) {
    //         _users[i] = _orders[i].user;
    //         _beans[i] = _orders[i].bean;
    //     }
    //     return (_users, _beans);
    // }

}


contract MosesContract is GuessBaseBiz {
//   // MOS合约地址 
//   address internal INITIAL_MOS_CONTRACT_ADDRESS = 0x001439818dd11823c45fff01af0cd6c50934e27ac0;
//   // 平台地址
//   address internal INITIAL_PLATFORM_ADDRESS = 0x00063150d38ac0b008abe411ab7e4fb8228ecead3e;
//   // 平台手续费
//   uint256 internal INITIAL_SERVICE_CHARGE_RATE = 5;
//   // 平台维护费
//   uint256 internal INITIAL_MAINTENANCE_CHARGE_RATE = 0;
//   // 单次上限
//   uint256 UPPER_LIMIT = 1000 * 10 ** 18;
//   // 单次下限
//   uint256 LOWER_LIMIT = 1 * 10 ** 18;
  
  
  constructor(address[] _operators) public {
    for(uint8 i = 0; i< _operators.length; i++) {
        operators[_operators[i]] = uint8(1);
    }
  }

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