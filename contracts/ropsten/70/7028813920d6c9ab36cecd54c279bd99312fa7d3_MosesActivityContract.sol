pragma solidity ^0.4.24;


contract Ownable {

    address public owner;

    mapping(address => uint8) public operators;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()public {
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
 *  一测到底合约对象
 *  @author ZhangZuoCong <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="85bcb5b2b2b1b6b7b6b2c5f4f4abe6eae8">[email&#160;protected]</a>>
 */
contract GuessBaseBiz is Pausable {



    // =============================== Event ===============================

    // 创建预测事件成功后广播
    event CreateGuess(uint256 indexed id, address indexed creator);

    // 代投事件
    event DepositAgent(address indexed participant, uint256 indexed id, uint256 optionId, uint256 totalBean);

    // 公布选项事件
    event PublishOption(uint256 indexed id, uint256 indexed optionId);

    // 预测事件流拍事件
    event Abortive(uint256 indexed id);

    event CreateActivity(uint256 indexed id, address indexed creator);

    struct Guess {
        // 预测事件ID
        uint256 id;
        // 预测事件信息
        string info;
        // 是否下架 1.是 0.否
        uint8 disabled;
        // 开始时间
        uint256 startAt;
        // 封盘时间
        uint256 endAt;
        // 是否结束
        uint8 finished;
        // 是否流拍
        uint8 abortive;
        //获胜倍数
        uint256 winMultiple;
    }

    // 平台代理订单
    struct AgentOrder {
        address participant;
        string ipfsBase58;
        string dataHash;
        uint256 bean;
    }

    struct Option {
        // 选项ID
        uint256 id;
        // 选项名称
        bytes32 name;
    }

    //预测活动
    struct Activity {
        // 预测活动ID
        uint256 id;
        // 预测事件创建者
        address creator;
        // 预测标题
        string title;
        // 开始时间
        uint256 startAt;
        // 结束时间
        uint256 endAt;
    }


    //通过预测活动ID和事件ID查找事件
    mapping (uint256 => mapping (uint256 => Guess)) public guesses;
    // 存储所有的预测事件选项
    mapping (uint256 => Option[]) public options;
    //存储所有的预测活动
    mapping (uint256 => Activity) public activities;
    //存储所有的活动对应的事件ID
    mapping (uint256 => uint256[]) public guessIds;

    //通过预测事件ID和选项ID，存储该选项所有参与的地址
    mapping (uint256 => mapping (uint256 => AgentOrder[])) public agentOrders;

    // 存储事件总投注
    mapping (uint256 => uint256) public guessTotalBean;

    // 存储某选项总投注
    mapping (uint256 => mapping(uint256 => uint256)) public optionTotalBean;

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
    function disabled(uint256 id,uint256 activityId) public view returns(bool) {
        if(guesses[activityId][id].disabled == 0){
            return false;
        }else {
            return true;
        }
    }

    function showGuessIds(uint256 activityId) public view returns(uint256[]){
        return guessIds[activityId];
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
    function getGuessStatus(uint256 guessId ,uint256 activityId)
    internal
    view
    returns(GuessStatus) {
        GuessStatus gs;
        Guess memory guess = guesses[activityId][guessId];
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
    function optionExist(uint256 guessId,uint256 optionId)
    internal
    view
    returns(bool){
        Option[] memory _options = options[guessId];
        for (uint8 i = 0; i < _options.length; i++) {
            if(optionId == _options[i].id){
                return true;
            }
        }
        return false;
    }

    //判断活动是否存在
    function activityExist(uint256 activityId) internal view returns(bool){
        if(activities[activityId].id == uint256(0)){
            return false;
        }
        return true;
    }


    function() public payable {
    }


    //创建预测活动
    function createActivity(uint256 _id,string _title,uint256 _startAt,uint256 _endAt)
    public
    whenNotPaused {
        require(!activityExist(_id), "The current activity already exists !!!");
        activities[_id] = Activity(_id,msg.sender,_title,_startAt,_endAt);
        emit CreateActivity(_id, msg.sender);
    }

    //审核修改预测活动
    function auditActivity(uint256 _id,string _title,uint256 _startAt,uint256 _endAt)
    public
    onlyOwner
    whenNotPaused {
        require(activityExist(_id), "The current activity not exists !!!");
        Activity storage activity = activities[_id];
        activity.title = _title;
        activity.startAt = _startAt;
        activity.endAt = _endAt;

    }

    // 创建预测事件
    function createGuess(
        uint256 _id,
        uint256 _activityId,
        string _info,
        uint8 _disabled,
        uint256 _startAt,
        uint256 _endAt,
        uint256[] _optionId,
        bytes32[] _optionName,
        uint256 _winMultiple
    )
    public
    whenNotPaused {
        require(activityExist(_activityId), "The current activity not exists !!!");
        require(guesses[_activityId][_id].id == uint256(0), "The current guess already exists !!!");
        require(_optionId.length == _optionName.length, "please check options !!!");

        guesses[_activityId][_id] = Guess(
            _id,
            _info,
            _disabled,
            _startAt,
            _endAt,
            0,
            0,
            _winMultiple
        );
        Option[] storage _options = options[_id];
        for (uint8 i = 0;i < _optionId.length; i++) {
            require(!optionExist(_id,_optionId[i]),"The current optionId already exists !!!");
            _options.push(Option(_optionId[i],_optionName[i]));
        }
        uint256[] storage _guessIds = guessIds[_activityId];
        _guessIds.push(_id);
        emit CreateGuess(_id, msg.sender);
    }

    /**
     * 审核|更新预测事件
     */
    function auditGuess(uint256 _id,string _info,uint8 _disabled,uint256 _endAt,uint256 _winMultiple,uint256 _activityId)
    public
    onlyOwner
    {
        require(activityExist(_activityId), "The current activity not exists !!!");
        require(guesses[_activityId][_id].id != uint256(0), "The current guess not exists !!!");
        require(getGuessStatus(_id,_activityId) == GuessStatus.NotStarted, "The guess cannot audit !!!");
        Guess storage guess = guesses[_activityId][_id];
        guess.info = _info;
        guess.disabled = _disabled;
        guess.endAt = _endAt;
        guess.winMultiple = _winMultiple;
    }

    /**
     * 平台代理用户参与事件预测
     */
    function depositAgent
    (
        uint256 id,
        uint256 activityId,
        uint256 optionId,
        string ipfsBase58,
        uint256 totalBean,
        string dataHash
    )
    public
    onlyOperator
    whenNotPaused
    returns (bool) {
        require(activityExist(activityId), "The current activity not exists !!!");
        require(guesses[activityId][id].id != uint256(0), "The current guess not exists !!!");
        require(optionExist(id, optionId),"The current optionId not exists !!!");
        require(!disabled(id,activityId), "The guess disabled!!!");
        require(getGuessStatus(id,activityId) == GuessStatus.Deadline, "The guess cannot participate !!!");
        // 通过预测事件ID和选项ID，存储该选项所有参与的地址
        AgentOrder[] storage _agentOrders = agentOrders[id][optionId];
        AgentOrder memory agentOrder = AgentOrder(msg.sender,ipfsBase58,dataHash,totalBean);
        _agentOrders.push(agentOrder);
        // 订单选项总投注
        optionTotalBean[id][optionId] += totalBean;
        // 存储事件总投注
        guessTotalBean[id] += totalBean;
        emit DepositAgent(msg.sender, id, optionId, totalBean);
        return true;
    }

    /**
     * 公布事件的结果
     */
    function publishOption(uint256 id, uint256 optionId ,uint256 activityId)
    public
    onlyOwner
    whenNotPaused
    returns (bool) {
        require(guesses[activityId][id].id != uint256(0), "The current guess not exists !!!");
        require(optionExist(id, optionId),"The current optionId not exists !!!");
        require(!disabled(id,activityId), "The guess disabled!!!");
        require(getGuessStatus(id,activityId) == GuessStatus.Deadline, "The guess cannot publish !!!");
        Guess storage guess = guesses[activityId][id];
        guess.finished = 1;
        emit PublishOption(id, optionId);
        return true;
    }


    /**
     * 事件流拍
     */
    function abortive(uint256 id,uint256 activityId)
    public
    onlyOwner
    returns(bool) {
        require(guesses[activityId][id].id != uint256(0), "The current guess not exists !!!");
        require(getGuessStatus(id,activityId) == GuessStatus.Progress ||
        getGuessStatus(id,activityId) == GuessStatus.Deadline, "The guess cannot abortive !!!");
        Guess storage guess = guesses[activityId][id];
        guess.abortive = 1;
        guess.finished = 1;
        emit Abortive(id);
        return true;
    }

}
contract MosesActivityContract is GuessBaseBiz {


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