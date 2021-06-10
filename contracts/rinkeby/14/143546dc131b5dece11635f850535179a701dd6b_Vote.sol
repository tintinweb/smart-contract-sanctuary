/**
 *Submitted for verification at Etherscan.io on 2021-06-10
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
/** 投票智能合约 */
contract Vote{  
    /** 定义候选者和所获得票数的映射 */ 
    mapping (address => uint256) public votesReceived;  
    /** 选民一共投了多少票 */
    mapping (address => uint256) public voterOgts;  
    
    mapping (address => mapping(address => uint256)) public voterCandidateOgts;

    /** 定义候选人 */
    address[] public candidateList;  
    /** 总的投票数 */
    uint256 public reserve;
    /** 投票结束时间  2022-05-31 00:00:00*/
    uint public voteEndTime = 1653926400;
    /** OTG的地址 */
    address private ogtAddress;
    
    address public manger;
    
    uint256 public decimals = 1000000000000000000;

    event updateVotes(address candidate,uint256 votes);
    
    event history(address voter,address candidate,uint256 amount);
   
    /** 构造方法,初始化有哪些候选者
    * @param candidateNames 选民
    * @param _ogtAddress 使用的哪种Token进行投票
    */
    function Vote(address[] candidateNames,address _ogtAddress) public {  
        candidateList = candidateNames; 
        ogtAddress = _ogtAddress;
        manger = msg.sender;
    }  

    /** 投票方法，选民给某个候选者投一定数量的票 
    * @param candidate 候选者
    * @param amount 数量
    */
    function voteForCandidate(address candidate,uint256 amount)  public returns (bool){  
        // 1. 校验当前时间没有超过投票截止时间
        // 2. 校验选民的otg数量大于等于他这次投的票数
        // 3. 校验选民所投的候选者在不在我们允许的候选者名单
        // 4. 选票数量数量大于1
        // 5. transfer(voter,address(this),amount) 锁仓
        // 6. 记录候选者得票数
        // 7. 记录选民投的票数
        require(now < voteEndTime);
        require(getOgtBalance(msg.sender) >= amount);
        require(validCandidate(candidate));
        uint256 voteNum = getNum(amount);
        require(voteNum>0);
        
        if(IERC20(ogtAddress).transferFrom(msg.sender,address(this), amount)){
            votesReceived[candidate] += voteNum; 
            voterOgts[msg.sender] += voteNum;
            reserve += voteNum;
            voterCandidateOgts[msg.sender][candidate] += voteNum;
            // 更新票数事件
            updateVotes(candidate,votesReceived[candidate]);
            history(msg.sender, candidate, voteNum);
            return true;
        }else{
            return false;
        }
      
    }  
    
    // 提现
    function withdraw(uint256 amount,address to) public{
        require(manger == msg.sender);
        require(getOgtBalance(address(this)) >= amount);
        IERC20(ogtAddress).transfer(to,amount);
    }
    /**  查看某个候选人的得票数 */
    function totalVotesFor(address candidate) view public returns (uint256 amount) {  
        return votesReceived[candidate];  
    }  

    /**  查看总票 */
    function reserve() view public returns(uint256) {  
        return reserve;  
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
    
    function getNum(uint256 amount)  private returns (uint256 voteNum){
         voteNum = amount / decimals;    
         return voteNum;
    }
    
    /** 获取某个账户的otg的余额 */
    function getOgtBalance(address account) private returns(uint256 amount) {
        return IERC20(ogtAddress).balanceOf(account);
    }
}