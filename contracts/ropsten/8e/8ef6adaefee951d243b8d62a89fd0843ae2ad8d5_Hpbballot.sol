pragma solidity ^0.4.24;

contract Hpbballot {
    
    uint256 constant public MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256 z){
        if (x > MAX_UINT256 - y) {
            revert();
        }
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) internal pure returns (uint256 z){
        if (x < y){
            revert();
        }
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) internal pure returns (uint256 z){
        if (y == 0){
            return 0;
        }
        if (x > MAX_UINT256 / y) {
            revert();
        }
        return x * y;
    }
    
    
    // 票池名称
    // pool name
    bytes32 public name = "HPBBallot";
    
    // 开始投票的区块号
    // startBlock specifies from which block our vote starts.
    uint public startBlock = 0;
    
    // 结束投票的区块号
    // endBlock specifies from which block our vote ends.
    uint public endBlock = 0;
    
    // 当前票池的版本号
    // currrent pool version
    uint public version = 1;
    
    // 候选者的结构体
    struct Candidate{
        
        // 候选人账户地址
        address candidateAddr;
        
        // 候选人名称
        bytes32 name;
        
        // 候选者机器id(编号或者节点)
        bytes32 facilityId;
        
        // 保证金金额
        uint balance;
        
        // 得票数
        uint numberOfVotes;
        
        //对候选者投票的投票者数组，用于遍历用途
        address[] voterMapAddrs;
        
        // 已经投票了投票人账户地址-》投票数
        mapping (address => uint) voterMap;
        
    }
    
    // 投票结构体
    struct Voter{
        
        //投票人的账户地址
        address voterAddr;
        
        //投票人已经投票数
        uint voteNumber;
        
        //用于遍历投票了的候选者用途
        address[] candidateMapAddrs;
        
        // 已经投票了的候选者账户地址-》投票数
        mapping (address => uint) candidateMap;
        
    }
    
    // 候选者的数组
    // An array of candidates
    Candidate[] public candidateArray;
    
    //候选者的地址与以上变量候选者数组（candidateArray）索引(数组下标)对应关系,用于查询候选者用途
    //这样可以降低每次遍历对象对gas的消耗，存储空间申请和申请次数远远小于查询次数，并且计票步骤更加复杂，相比较消耗gas更多
    mapping (address => uint) public candidateIndexMap;
   
    // 候选者保证金最少金额，比如1000个HPB(10 ** 20)
    uint public minAmount = 10 ** 20;
    
    //是否已经释放保证金
    bool public hasReleaseAmount=false;
    
    // An array of voters
    //投票者数组
    Voter[] public voterArray;
    
    //最终获选者总数（容量，获选者数量上限）
    uint public capacity;
    
    // 投票者的地址与投票者序号（voterArray下标）对应关系，便于查询和减少gas消耗
    mapping (address => uint) public voterIndexMap;
    
    // 增加候选者
    event CandidateAdded(address indexed candidateAddr,bytes32 indexed facilityId,uint serialNumber,bytes32 name);
    
    // 更新候选者
    event CandidateUpdated(address indexed candidateAddr,bytes32 indexed facilityId,uint serialNumber,bytes32 name);
    
    // 投票
    event Voted(address indexed VoteAddr,address indexed candidateAddr,bytes32 facilityId,uint serialNumber);
    
    // 改变投票区间值,改变保证金最少金额,改变投票版本号
    event ChangeOfBlocks(uint indexed version,uint startBlock, uint endBlock,uint minAmount,uint capacity);

    // 记录发送HPB的发送者地址和发送的金额
    event receivedEther(address indexed sender, uint amount);

	//接受HPB转账
    function () payable  external{
       emit receivedEther(msg.sender, msg.value);
    }
    
 	address public owner;
    
	/**
	 * 只有HPB基金会账户（管理员）可以调用
	 */
    modifier onlyOwner{
        require(msg.sender == owner);
        // Do not forget the "_;"! It will be replaced by the actual function
        // body when the modifier is used.
        _;
    }

    function transferOwnership(address newOwner) onlyOwner  public{
        owner = newOwner;
    }
    /**
     * Constructor function
     * 构造函数
     * 初始化投票智能合约的部分依赖参数
     */
    constructor(
        //开始投票的区块号
    	// `startBlock` specifies from which block our vote starts.
        uint _startBlock,
         
        //结束投票的区块号
        // `endBlock` specifies from which block our vote ends.
        uint _endBlock,
         
        //保证金最少金额
        uint _minAmount,
        
        //获选者总量
        uint _capacity,
         
        //当前票池的版本号
        //currrent pool version
        uint _version
     ) payable public{
         	owner = msg.sender;
	        startBlock= _startBlock;
	        endBlock= _endBlock;
	        minAmount=_minAmount;
	        capacity=_capacity;
	        version=_version;
	        
	        //设置第一位置
	        voterIndexMap[msg.sender]=0;
            voterArray.push(Voter(msg.sender,0,new address[](0)));
            
            candidateIndexMap[msg.sender]=0;
	        candidateArray.push(Candidate(msg.sender,&#39;0&#39;,&#39;0&#39;,0,0,new address[](0)));
            
	        emit ChangeOfBlocks(_version,startBlock,_endBlock,_minAmount,_capacity);
     }

   /**
    * 
     * 管理员修改投票智能合约的部分依赖参数
     */
    function changeVotingBlocks(
        uint _startBlock,
        uint _endBlock,
        uint _minAmount,
        uint _capacity,
        uint _version
    ) onlyOwner public{
        startBlock = _startBlock;
        endBlock = _endBlock;
        minAmount = _minAmount;
        capacity = _capacity;
        version = _version;
        emit ChangeOfBlocks(_version,_startBlock, _endBlock,_minAmount,_capacity);
    }
    
    /**
     * 管理员启动投票开始
     */
    function beginVote() onlyOwner public{
        startBlock = block.number;
    }
    /**
     * 管理员启动投票结束
     */
    function endVote() onlyOwner public{
        endBlock = block.number;
    }
    /**
     * 只有投票开始后执行
     */
    modifier onlyVoteAfterStart{
        require(block.number>= startBlock);
        _;
    }
    /**
     * 只有投票进行中执行
     */
    modifier onlyVoteInProgress{
        require(block.number>= startBlock);
        require(block.number<= endBlock);
        _;
    }

    /**
     * 只有投票结束前执行
     */
    modifier onlyVoteBeforeEnd{
        require(block.number<= endBlock);
        _;
    }

    /**
     * 只有投票结束后执行
     */
    modifier onlyVoteAfterEnd{
        require(block.number> endBlock);
        _;
    }

    /**
     * add Candidate 增加候选者
     * 
     * @param _candidateAddr 候选者账户地址，用于还回保证金（HPB）
     * @param _facilityId 候选者机器设备号或者节点ID
     * @param _name 候选者名称
     * 
     */
    function addCandidate(
        address _candidateAddr,
        bytes32 _facilityId,
        bytes32 _name
    ) onlyOwner onlyVoteBeforeEnd public{
        uint index = candidateIndexMap[_candidateAddr];
        // 判断候选人是否已经存在
        if (index == 0) { // 如果没有，就添加
            index = candidateArray.length;
            candidateIndexMap[_candidateAddr]=index;
	        candidateArray.push(Candidate(_candidateAddr,_name,_facilityId,0,0,new address[](0)));
	        emit CandidateAdded(_candidateAddr,_facilityId,index,_name);
        }
    }
    /**
     * update Candidate 更新候选者
     * @param _candidateAddr 候选者账户地址，用于还回保证金（HPB）
     * @param _facilityId 候选者机器设备号或者节点ID
     * @param _name 候选者名称
     * 
     */
    function updateCandidate(
        address _candidateAddr,
        bytes32 _facilityId,
        bytes32 _name
    ) onlyOwner onlyVoteBeforeEnd public{
        // 判断候选人是否已经存在
        require(candidateIndexMap[_candidateAddr] != 0);
        uint index = candidateIndexMap[_candidateAddr];
        candidateArray[index].facilityId=_facilityId;
        candidateArray[index].name=_name;
        emit CandidateUpdated(_candidateAddr,_facilityId,index,_name);
    }

    /**
     * Delete Candidate 删除候选者
     * @param _candidateAddr 候选者账户地址
     */
    function deleteCandidates(
        address _candidateAddr
    ) onlyOwner onlyVoteBeforeEnd public{
        require(candidateIndexMap[_candidateAddr] != 0);
        for (uint i = candidateIndexMap[_candidateAddr];i<candidateArray.length-1;i++){
            candidateArray[i] = candidateArray[i+1];
        }
        delete candidateArray[candidateArray.length-1];
        candidateArray.length--;
        candidateIndexMap[_candidateAddr]=0;
    }
    /**
     * 缴纳保证金
     */
    function payDepositByCandidate() onlyVoteBeforeEnd payable public{
        uint index = candidateIndexMap[msg.sender];
        // 判断候选人是否已经存在
        require(candidateIndexMap[msg.sender] != 0);
        uint balance=safeAdd(candidateArray[index].balance,msg.value);
        candidateArray[index].balance=balance;
    }
    /**
     * 用于非质押(锁定)投票多候选人
      */
    function multiVoteNoLock(
        address[] candidateAddr,
    	uint[] num
    )onlyVoteInProgress public {
        // 获取投票人的账户地址
        address voterAddr = msg.sender;
        updateVoteInfo(voterAddr);
    	uint index=voterIndexMap[voterAddr];
    	
        if (index == 0) { // 如果从没投过票，就添加投票人
            index =voterArray.length;
            voterIndexMap[voterAddr] =index;
            voterArray.push(Voter(voterAddr,0,new address[](0)));
        }
        
        for(uint i=0;i<num.length;i++){
            doVote(candidateAddr[i],index,num[i]);
        }
        
	}
 	/**
     * 用于非质押(锁定)投票
      */
    function  voteNoLock(
    	address candidateAddr,
    	uint num
    ) onlyVoteInProgress public {
        // 获取投票人的账户地址
        address voterAddr = msg.sender;
        updateVoteInfo(voterAddr);
        
        require(voterAddr.balance>=num);
        
        uint index=voterIndexMap[voterAddr];
        if (index == 0) { // 如果从没投过票，就添加投票人
            index =voterArray.length;
            voterIndexMap[voterAddr] =index;
            voterArray.push(Voter(voterAddr,0,new address[](0)));
        }
        doVote(candidateAddr,index,num);
    }
    /**
     * 执行投票
      */
    function doVote(
        address candidateAddr,
        uint index,
    	uint num
    ) onlyVoteInProgress internal {
        require(num>0);
        //已经投票数
        uint voteNumber=voterArray[index].voteNumber;
        
        uint bal=voterArray[index].voterAddr.balance;
        //剩余余额
        uint cbal=safeSub(bal,voteNumber);
        
        require(cbal>=num);
            
        uint candidateIndex=candidateIndexMap[candidateAddr];
        //候选人必须存在
        require(candidateIndex!=0);
        // Get the candidate 获取候选人
        // 必须缴纳足够的保证金
        require(candidateArray[candidateIndex].balance>=minAmount);
        
        // 获取候选人中的投票人信息，并重新记录投票数
        if(candidateArray[candidateIndex].voterMap[voterArray[index].voterAddr]==0)	{
            candidateArray[candidateIndex].voterMap[voterArray[index].voterAddr]=num;
        } else {
            candidateArray[candidateIndex].voterMap[voterArray[index].voterAddr]=
            safeAdd(candidateArray[candidateIndex].voterMap[voterArray[index].voterAddr],num);
        }
        bool hasVoterAddr=false;
        for (uint i = 1;i<candidateArray[candidateIndex].voterMapAddrs.length-1;i++){
            if(voterArray[index].voterAddr==candidateArray[candidateIndex].voterMapAddrs[i]){
                hasVoterAddr=true;
                break;
            }
	    }
	    if(!hasVoterAddr){
	        //待测试，是否可以使用push
	        candidateArray[candidateIndex].voterMapAddrs.push(voterArray[index].voterAddr);
	        //uint vl=candidateArray[candidateIndex].voterMapAddrs.length;
	        //candidateArray[candidateIndex].voterMapAddrs.length=safeAdd(vl,1);
	        //candidateArray[candidateIndex].voterMapAddrs[vl]=voterAddr;
	    }
        
        
        voterArray[index].voteNumber=safeAdd(voteNumber,num);
        uint candidateNum=voterArray[index].candidateMap[candidateAddr];
        voterArray[index].candidateMap[candidateAddr]=safeAdd(candidateNum,num);
        
        if(voterArray[index].candidateMapAddrs.length==0){
            //这里待测试 ,是否可以调用push
            voterArray[index].candidateMapAddrs.push(candidateAddr);
            //uint cl=voterArray[index].candidateMapAddrs.length;
		    //voterArray[index].candidateMapAddrs.length=safeAdd(cl,1);
		    //voterArray[index].candidateMapAddrs[cl]=candidateAddr;
        }else{
            bool hasAddr=false;
            for (uint k = 1;k<voterArray[index].candidateMapAddrs.length-1;k++){
	            if(candidateAddr== voterArray[index].candidateMapAddrs[k]){
	                hasAddr=true;
	                break;
	            }
		    }
		    if(!hasAddr){
		        //这里待测试 ,是否可以调用push
		        voterArray[index].candidateMapAddrs.push(candidateAddr);
		        //uint l=voterArray[index].candidateMapAddrs.length;
		        //voterArray[index].candidateMapAddrs.length=safeAdd(l,1);
		        //voterArray[index].candidateMapAddrs[l]=candidateAddr;
		    }
        }
    }
    
    /**
     * 
     * 对于投过票的,更新投票信息
     * 用于扣除无效的投票情况，保留最新的，移除最老的
      */
    function updateVoteInfo(
        address voterAddr
    ) onlyVoteInProgress internal {
        uint index=voterIndexMap[voterAddr];
        if(index!= 0){//必须投过票才进行
            uint bal=voterAddr.balance;
            //已经投票数
            uint voteNumber=voterArray[index].voteNumber;
            //如果投票数大于余额，开始扣除无效的投票，否则不变化
            if(voteNumber>bal){
                //重置投票数量为余额
                voterArray[index].voteNumber=bal;
                
                //从最后一个候选人开始计算投票数量
                uint i=voterArray[index].candidateMapAddrs.length;
                while(i>1){
                    i--;
                    if(voterArray[index].candidateMap[voterArray[index].candidateMapAddrs[i]]<bal){
                        //向前推，每一个候选人选票扣除一次余额
                        bal=bal-voterArray[index].candidateMap[voterArray[index].candidateMapAddrs[i]];
                    }else {
                        //如果余额不够，就停止，改变当前的投票数
                       voterArray[index].candidateMap[voterArray[index].candidateMapAddrs[i]]=bal;
                       break;
                    }
                }
                uint k=0;
                //重新放置已投候选人数组
                while(k<voterArray[index].candidateMapAddrs.length){
                    if(i>voterArray[index].candidateMapAddrs.length){
                        //已经到达最后一个
                        break;
                    }
		            k++;
		            voterArray[index].candidateMapAddrs[k] = voterArray[index].candidateMapAddrs[i];
		            i++;
		        }
                
                //移除无效的投票以及对应的候选人
                uint p=voterArray[index].candidateMapAddrs.length-1;
                while(p>k){
		            voterArray[index].candidateMap[voterArray[index].candidateMapAddrs[p]]=0;
		            delete voterArray[index].candidateMapAddrs[p];
		            voterArray[index].candidateMapAddrs.length--;
		            p--;
		        }
            }
        }
    }
    
     /**
     * 
     *更新候选人的得票情况
      */
    function updateCandidateInfo(
        address candidateAddr
    ) onlyVoteInProgress internal {
       uint index=candidateIndexMap[candidateAddr]; 
       if(index!= 0){//必须是候选人才进行
          uint  n=0;
          for (uint i=1;i<candidateArray[index].voterMapAddrs.length;i++){
              updateVoteInfo(candidateArray[index].voterMapAddrs[i]);
              candidateArray[index].voterMap[candidateArray[index].voterMapAddrs[i]]=
              voterArray[voterIndexMap[candidateArray[index].voterMapAddrs[i]]].candidateMap[candidateAddr];
              n=safeAdd(n,candidateArray[index].voterMap[candidateArray[index].voterMapAddrs[i]]);
          }
          candidateArray[index].numberOfVotes=n;
          deleteVoterForCandidate(index);
       }
    }
      /**
     * 
     * 为候选人删除投票为零的记录
      */
    function deleteVoterForCandidate(
        uint index
    ) onlyVoteInProgress internal {
        uint  i = 1;
        uint  l =candidateArray[index].voterMapAddrs.length;
        while(i<l){
             if(i==candidateArray[index].voterMapAddrs.length){
                 //已经到达末尾
                 break;
             }
             if(candidateArray[index].voterMap[candidateArray[index].voterMapAddrs[i]]==0){
	           for (uint k=i;k<candidateArray[index].voterMapAddrs.length-1;k++){
		            candidateArray[index].voterMapAddrs[k] = candidateArray[index].voterMapAddrs[k+1];
		       }
		       delete candidateArray[index].voterMapAddrs[candidateArray[index].voterMapAddrs.length-1];
		       candidateArray[index].voterMapAddrs.length--;
             }else{
               i++;
             }
        }
        
    }
    /**
     * 释放保证金
     */
    function releaseAmount(
    ) onlyOwner onlyVoteAfterEnd public{
        if(!hasReleaseAmount){
            hasReleaseAmount=true;
            for (uint i = 0;i<candidateArray.length-1;i++){
                if(candidateArray[i].balance>0){
                    candidateArray[i].candidateAddr.transfer(candidateArray[i].balance);
                    candidateArray[i].balance=0;
                }
            }
        }
    }
   
   
    /**
     * 得到即时投票结果
      */
    function voteCurrentResult(
    ) onlyVoteAfterStart public returns(
        address[] addr,
        bytes32[] _facilityIds,
        uint[] nums
    ){ 
        return voteResult();
    }
    /**
     * 得到最终投票结果
      */
    function voteResult(
    ) onlyVoteAfterEnd public returns(
        address[] addr,
        bytes32[] facilityIds,
        uint[] nums
    ){ 
         address[] memory _addrs=new address[](capacity);
         bytes32[] memory _facilityIds=new bytes32[](capacity);
         uint[] memory _nums=new uint[](capacity);
         uint min=candidateArray[1].numberOfVotes;
         uint minIndex=0;
         for (uint i = 1;i<candidateArray.length-1;i++){
             //即时更新得票情况，根据投票人的实际持币数量
             updateCandidateInfo(candidateArray[i].candidateAddr);
             if(!hasReleaseAmount){//还没释放保证金，就释放保证金
	             if(candidateArray[i].balance>0){
	                 candidateArray[i].candidateAddr.transfer(candidateArray[i].balance);
	                 candidateArray[i].balance=0;
	             }
             }
             if(i<=capacity){
                 //先初始化获选者数量池
                 _addrs[i-1]=candidateArray[i].candidateAddr;
                 _facilityIds[i-1]=candidateArray[i].facilityId;
                 _nums[i-1]=candidateArray[i].numberOfVotes;
                 //先记录获选者数量池中得票最少的记录
                 if(_nums[i-1]<min){
                     min=_nums[i-1];
                     minIndex=i-1;
                 }
             }else{
               if(candidateArray[i].numberOfVotes==min){
                   //对于得票相同的，取持币数量多的为当选
                   if(candidateArray[i].candidateAddr.balance>_addrs[minIndex].balance){
                       _addrs[minIndex]=candidateArray[i].candidateAddr;
		               _facilityIds[minIndex]=candidateArray[i].facilityId;
		               _nums[minIndex]=candidateArray[i].numberOfVotes;
                   }
               }else if(candidateArray[i].numberOfVotes>min){
              	   _addrs[minIndex]=candidateArray[i].candidateAddr;
	               _facilityIds[minIndex]=candidateArray[i].facilityId;
	               _nums[minIndex]=candidateArray[i].numberOfVotes;
	               //重新记下最小得票者
	               min=_nums[minIndex];
               }
             }
        }
        hasReleaseAmount=true;
        return (_addrs,_facilityIds,_nums);
    }
    
    /**
     * 获取投票人的所有投票情况
     */
    function fechVoteInfoForVoter(
    ) onlyVoteAfterStart public returns (
        address[] addrs,
        uint[] nums
    ){
        uint index = voterIndexMap[msg.sender];
        require(index> 0);
        //如果投过票，就获取投票人对应的投票候选者(多个，以map形式存放)
        updateVoteInfo(msg.sender);
        uint[] memory _nums=new uint[](voterArray[index].candidateMapAddrs.length);
        for (uint i = 0;i<voterArray[index].candidateMapAddrs.length-1;i++){
            _nums[i]=voterArray[index].candidateMap[voterArray[index].candidateMapAddrs[i]];
        }
        return (voterArray[index].candidateMapAddrs,_nums);
    }
    
    /**
     * 获取候选人的竞选结果
     */
    function fechVoteNumForCandidate(
    ) onlyVoteAfterStart public returns (
        uint num
    ){
        uint index = candidateIndexMap[msg.sender];
        require(index>0);
        // 如果候选人存在,即时更新竞选情况
        updateCandidateInfo(msg.sender);
        return candidateArray[index].numberOfVotes;
    }
    /**
     * 获取候选人的竞选详细情况，包括投票者
     */
    function fechVoteResultForCandidate(
    ) onlyVoteAfterStart public returns (
        address[] addr,
        uint[] nums
    ){
        uint index = candidateIndexMap[msg.sender];
        require(index>0);
        // 如果候选人存在,即时更新竞选情况
        updateCandidateInfo(msg.sender);
        uint[] memory _nums=new uint[](candidateArray[index].voterMapAddrs.length);
        for (uint i = 0;i<candidateArray[index].voterMapAddrs.length-1;i++){
            _nums[i]=candidateArray[index].voterMap[candidateArray[index].voterMapAddrs[i]];
        }
        return (candidateArray[index].voterMapAddrs,_nums);
    }
}