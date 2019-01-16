pragma solidity ^0.4.24;

/**
  Ownable
 */
contract Ownable {

    address public owner;

    mapping(address => uint8) public operators;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

    function balanceOf(address _owner) view public returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);
}


/**
 *  预测事件合约对象
 *  @author ZhangZuoCong <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f1c8c1c6c6c5c2c3c2c6b18080df929e9c">[email&#160;protected]</a>>
 */
contract GuessBaseBiz is Pausable {
    // MOS合约地址 
    address public mosContractAddress = 0xbC668E5c79992Cc26C9B979dC10F397C3C816067;
    // 平台地址
    address public platformAddress = 0xd4e2c6c3C7f3Aa77e960f41c733973082F9Df9A3;
    // 平台手续费
    uint256 public serviceChargeRate = 5;
    // 平台维护费
    uint256 public maintenanceChargeRate = 0;

     ERC20Token MOS;

    // =============================== Event ===============================

    // 创建预测事件成功后广播
    event CreateGuess(uint256 indexed id, address indexed creator);

    // 代投事件
    event DepositAgent(address indexed participant, uint256 indexed id, uint256 templateId, uint256 optionId, uint256 totalBean, uint8 currency);

    // 公布选项事件
    event PublishOption(uint256 indexed id,uint8 indexed currency ,uint256 indexed optionId, uint256 odds);

    // 预测事件流拍事件
    event Abortive(uint256 indexed id);

    constructor() public {
      MOS = ERC20Token(mosContractAddress);
    }

    // 预测
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
    }

    // 选项
    struct Option {
        // 选项ID
        uint256 id;
        // 预测方向ID
        uint256 templateId;
        // 选项名称
        bytes32 name;
    }

    // 平台代理订单
    struct AgentOrder {
        address participant;
        string ipfsBase58;
        string dataHash;
        uint256 bean;
        // 专场  0 MOS 1 ETH
        uint8 currency;
    }



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
    


    // 存储所有的预测事件
    mapping (uint256 => Guess) public guesses;
    // 存储所有的预测事件选项
    mapping (uint256 => mapping(uint256 => Option[])) public options;
    // 通过预测事件ID和选项ID，存储该选项所有参与的地址
    mapping (uint256 => mapping (uint256 => AgentOrder[])) public agentOrders;
    // 存储事件总投注
    mapping (uint256 => mapping (uint256 => uint256)) public guessTotalBeanMOS;
    // 存储某选项总投注
    mapping (uint256 => mapping(uint256 => mapping (uint256 => uint256))) public optionTotalBeanMOS;
    // 存储事件总投注ETH
    mapping (uint256 => mapping (uint256 => uint256)) public guessTotalBeanETH;
    // 存储某选项总投注ETH
    mapping (uint256 => mapping(uint256 => mapping (uint256 =>uint256))) public optionTotalBeanETH;




    modifier guessNotExists(uint256 _id){
          require(guesses[_id].id == uint256(0), "The current guess already exists !!!");
          _;
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

    //判断选项是否存在
    function optionExist(uint256 _guessId,uint256 _templateId,uint256 _optionId)
    internal
    view
    returns(bool){
        Option[] memory _options = options[_guessId][_templateId];
        for (uint8 i = 0; i < _options.length; i++) {
            if(_optionId == _options[i].id){
                return true;
            }
        }
        return false;
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
        uint256 _maintenanceChargeRate
    )
    public
    onlyOwner
    {
        platformAddress = _platformAddress;
        serviceChargeRate = _serviceChargeRate;
        maintenanceChargeRate = _maintenanceChargeRate;
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
        uint256[] _optionIds,
        uint256[] _templateIds,
        bytes32[] _optionNames
    )
    public
    whenNotPaused guessNotExists(_id){
        require(_optionIds.length == _optionNames.length, "please check options !!!");
      
        saveGuess(
          _id,
          _title,
          _source,
          _category,
          _disabled,
          _desc,
          _startAt,
          _endAt);
                
        saveOptions(_id, _templateIds, _optionIds, _optionNames);
        
      
        emit CreateGuess(_id, msg.sender);
    }

    function saveOptions(uint256 _id,uint256[] _templateIds, uint256[] _optionIds,bytes32[] _optionNames)internal{

        for (uint8 i = 0;i < _optionIds.length; i++) {
            Option[] storage _options = options[_id][_templateIds[i]];
            require(!optionExist(_id, _templateIds[i],_optionIds[i]),"The current optionId already exists !!!");
            _options.push(Option(_optionIds[i],_templateIds[i],_optionNames[i]));
        }
    }
    
    function saveGuess(
        uint256 _id,
        string _title,
        string _source,
        string _category,
        uint8 _disabled,
        bytes _desc,
        uint256 _startAt,
        uint256 _endAt) internal {
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
                    0
                );
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
    * 平台代理用户参与事件预测
    */
  function depositAgentMOS
  (
      uint256 _id, 
      uint256 _templateId,
      uint256 _optionId, 
      string _ipfsBase58,
      string _dataHash,
      uint256 _totalBean
  ) 
    public
    onlyOperator
    whenNotPaused
    returns (bool) {
    require(guesses[_id].id != uint256(0), "The current guess not exists !!!");
    require(optionExist(_id, _templateId, _optionId),"The current optionId not exists !!!");
    require(!disabled(_id), "The guess disabled!!!");
    require(getGuessStatus(_id) == GuessStatus.Deadline, "The guess cannot participate !!!");
    
    // 通过预测事件ID和选项ID，存储该选项所有参与的地址
    AgentOrder[] storage _agentOrders = agentOrders[_id][_optionId];
    
    AgentOrder memory agentOrder = AgentOrder(msg.sender,_ipfsBase58,_dataHash,_totalBean,0);
    _agentOrders.push(agentOrder);
   
    MOS.transferFrom(msg.sender, address(this), _totalBean);
    
    // 订单选项总投注 
    optionTotalBeanMOS[_id][_templateId][_optionId] += _totalBean;
    // 存储事件总投注
    guessTotalBeanMOS[_id][_templateId] += _totalBean;
    
    emit DepositAgent(msg.sender, _id, _templateId,_optionId, _totalBean, 0);
    return true;
  }



    /**
     * 平台代理用户参与事件预测
     */
    function depositAgentETH
    (
        uint256 _id,
        uint256 _templateId,
        uint256 _optionId,
        string _ipfsBase58,
        string _dataHash
    )
    public
    payable
    onlyOperator
    whenNotPaused
    returns (bool) {
        require(guesses[_id].id != uint256(0), "The current guess not exists !!!");
        require(optionExist(_id,_templateId, _optionId),"The current optionId not exists !!!");
        require(!disabled(_id), "The guess disabled!!!");
        require(getGuessStatus(_id) == GuessStatus.Deadline, "The guess cannot participate !!!");
        // 通过预测事件ID和选项ID，存储该选项所有参与的地址
        AgentOrder[] storage _agentOrders = agentOrders[_id][_optionId];
        AgentOrder memory agentOrder = AgentOrder(msg.sender,_ipfsBase58,_dataHash,msg.value,1);
        _agentOrders.push(agentOrder);
        // 订单选项总投注
        optionTotalBeanETH[_id][_templateId][_optionId] += msg.value;
        // 存储事件总投注
        guessTotalBeanETH[_id][_templateId] += msg.value;
        emit DepositAgent(msg.sender, _id, _templateId,_optionId, msg.value, 1);
        return true;
    }

    /**
     * 公布事件的结果
     */
    function publishOption
    (
        uint256 _id,
        uint256 _templateId,
        uint256 _optionId
    )
    public
    onlyOwner
    whenNotPaused
    returns (bool) {
        require(guesses[_id].id != uint256(0), "The current guess not exists !!!");
        require(optionExist(_id, _templateId,_optionId),"The current optionId not exists !!!");
        require(!disabled(_id), "The guess disabled!!!");
        require(getGuessStatus(_id) == GuessStatus.Deadline, "The guess cannot publish !!!");
        Guess storage guess = guesses[_id];
        guess.finished = 1;
        // MOS 订单详细

        // 成功选项投注总数
        uint256 _optionTotalBeanMOS;
        // 判断是否低赔率事件
        uint256 oddsMOS;
        // 该预测事件总投注
        uint256 totalBeanMOS = guessTotalBeanMOS[_id][_templateId];

        if(totalBeanMOS > 0){
            // 成功选项投注总数
            _optionTotalBeanMOS = optionTotalBeanMOS[_id][_templateId][_optionId];
            // 判断是否低赔率事件
            oddsMOS = totalBeanMOS * (100 - serviceChargeRate - maintenanceChargeRate) / _optionTotalBeanMOS;
            emit PublishOption(_id,0, _optionId, oddsMOS);
        }
        
        // ETH 订单详细
        // 成功选项投注总数
        uint256 _optionTotalBeanETH;
        // 判断是否低赔率事件
        uint256 oddsETH;
        // 该预测时间总投注
        uint256 totalBeanETH = guessTotalBeanETH[_id][_templateId];

        if(totalBeanETH > 0){
            // 成功选项投注总数
            _optionTotalBeanETH = optionTotalBeanETH[_id][_templateId][_optionId];
            // 判断是否低赔率事件
            oddsETH = totalBeanETH * (100 - serviceChargeRate - maintenanceChargeRate) / _optionTotalBeanETH;
            emit PublishOption(_id,1, _optionId, oddsETH);
        }
        
        
        // 订单合集
        AgentOrder[] memory _agentOrders = agentOrders[_id][_optionId];
        
        for(uint8 i = 0; i< _agentOrders.length; i++ ){
           
           if(_agentOrders[i].currency == uint8(0)){
               // MOS 转账
                transferMOS(_agentOrders[i],totalBeanMOS,_optionTotalBeanMOS, oddsMOS);
           }else{
               // ETH 转账
               transferETH(_agentOrders[i],totalBeanETH,_optionTotalBeanETH,oddsETH);
           }
            
        }
        
        return true;
    }
    
    
    
    function transferMOS(AgentOrder _order,uint256 totalBean, uint256 _optionTotalBean,uint256 odds) internal {
      if(odds >= uint256(100)){
        // 平台收取手续费
        uint256 platformFee = totalBean * (serviceChargeRate + maintenanceChargeRate) / 100;
        MOS.transfer(platformAddress, platformFee);
        MOS.transfer(_order.participant, (totalBean - platformFee) * _order.bean  / _optionTotalBean);
      } else {
        // 低赔率事件，平台不收取手续费
        MOS.transfer(_order.participant, totalBean * _order.bean / _optionTotalBean);
      }
    }

    function transferETH(AgentOrder _order,uint256 totalBean, uint256 _optionTotalBean,uint256 odds) internal{
        if(odds >= uint256(100)){
          // 平台收取手续费
          uint256 platformFee = totalBean * (serviceChargeRate + maintenanceChargeRate) / 100;
          platformAddress.transfer(platformFee);
          _order.participant.transfer((totalBean - platformFee) * _order.bean / _optionTotalBean);
        } else {
          // 低赔率事件，平台不收取手续费
          _order.participant.transfer(totalBean * _order.bean / _optionTotalBean);
          
        }
    }

    /**
     * 事件流拍
     */
    function abortive
    (
        uint256 _id,
        uint256[] _templateIds
    )
    public
    onlyOwner
    returns(bool) {
        require(guesses[_id].id != uint256(0), "The current guess not exists !!!");
        require(getGuessStatus(_id) == GuessStatus.Progress ||
        getGuessStatus(_id) == GuessStatus.Deadline, "The guess cannot abortive !!!");
        Guess storage guess = guesses[_id];
        guess.abortive = 1;
        guess.finished = 1;
        // 退回
        for( uint8 j = 0; j < _templateIds.length; j++){
            Option[] memory _options = options[_id][_templateIds[j]];
            for(uint8 i = 0; i< _options.length;i ++){
                //代投退回
                AgentOrder[] memory _agentOrders = agentOrders[_id][_options[i].id];
                for(uint8 k = 0; k < _agentOrders.length; k++){
                    uint256 _bean = _agentOrders[k].bean;

                    if(_agentOrders[j].currency == uint8(0)){
                        // MOS 订单
                        MOS.transfer(_agentOrders[j].participant, _bean);
                    }else{
                        // ETH 订单
                        _agentOrders[j].participant.transfer(_bean);
                    }

                }
            }
        }
        
        emit Abortive(_id);
        return true;
    }

}

contract SscContract is GuessBaseBiz {


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