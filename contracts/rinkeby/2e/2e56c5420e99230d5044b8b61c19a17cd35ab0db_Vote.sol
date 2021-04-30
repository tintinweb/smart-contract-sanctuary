/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

pragma solidity ^0.4.16;
contract IERC20{
    // token总量，默认会为public变量生成一个getter函数接口，名称为totalSupply().
    uint256 public totalSupply;

    /// 获取账户_owner拥有token的数量 
    function balanceOf(address _owner) constant returns (uint256 balance);

    //从消息发送者账户中往_to账户转数量为_value的token
    function transfer(address _to, uint256 _value) returns (bool success);

    //从账户_from中往账户_to转数量为_value的token，与approve方法配合使用
    function transferFrom(address _from, address _to, uint256 _value) returns   
    (bool success);

    //消息发送账户设置账户_spender能从发送账户中转出数量为_value的token
    function approve(address _spender, uint256 _value) returns (bool success);

    //获取账户_spender可以从账户_owner中转出token的数量
    function allowance(address _owner, address _spender) constant returns 
    (uint256 remaining);

    //发生转账时必须要触发的事件 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    //当函数approve(address _spender, uint256 _value)成功执行时必须触发的事件
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
}

pragma solidity ^0.4.16;
contract Ogt {
    string public name;
    string public symbol;
    uint8 public decimals = 18;  // 18 是建议的默认值
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;  //
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Burn(address indexed from, uint256 value);


    function Ogt(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }


    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // require(_value <= allowance[_from][msg.sender]);     // Check allowance
        // allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}

pragma solidity ^0.4.16;
/** 投票智能合约 */
contract Vote{  
    /** 定义候选者和所获得票数的映射 */ 
    mapping (address => uint256) public votesReceived;  
    /** 选民一共投了多少票 */
    mapping (address => uint256) public voterOgts;  

    /** 定义候选人 */
    address[] public candidateList;  
    /** OGT储备量 */
    uint112 private reserve;
    /** 投票结束时间  20210528 00:00:00*/
    uint public voteEndTime = 1622131200;
    /** OTG的地址 */
    address private ogtAddress;
    event updateVotes(address candidate , uint256 votes);

    /** 构造方法,初始化有哪些候选者
    * @param candidateNames 选民
    * @param _ogtAddress 使用的哪种Token进行投票
    */
    function Vote(address[] candidateNames,address _ogtAddress) public {  
        candidateList = candidateNames; 
        ogtAddress = _ogtAddress;
    }  

    /** 投票方法，选民给某个候选者投一定数量的票 
    * @param voter 选民
    * @param candidate 候选者
    * @param amount 数量
    */
    function voteForCandidate(address voter,address candidate,uint256 amount)  public{  
        // 1. 校验当前时间没有超过投票截止时间
        // 2. 校验选民的otg数量大于等于他这次投的票数
        // 3. 校验选民所投的候选者在不在我们允许的候选者名单
        // 4. transfer(voter,address(this),amount) 锁仓
        // 5. 记录候选者得票数
        // 6. 记录选民投的票数
        require(now < voteEndTime);
        require(getOgtBalance(voter) >= amount);
        require(validCandidate(candidate));
        IERC20(ogtAddress).transferFrom(voter,address(this), amount);
        votesReceived[candidate] += amount; 
        voterOgts[voter] += amount;
        // 更新票数事件
        updateVotes(candidate,votesReceived[candidate]);
    }  

    /**  查看某个候选人的得票数 */
    function totalVotesFor(address candidate) view public returns (uint256 amount) {  
        return votesReceived[candidate];  
    }  

    /** 验证是不是合法的候选人 */
    function validCandidate(address candidate) view public returns (bool result) {  
        for(uint i = 0; i < candidateList.length; i++) {  
            if (candidateList[i] == candidate) {  
                return true;  
            }  
        }  
        return false;  
    }  

    /** 获取某个账户的otg的余额 */
    function getOgtBalance(address account) private returns(uint256 amount) {
        return IERC20(ogtAddress).balanceOf(account);
    }
}