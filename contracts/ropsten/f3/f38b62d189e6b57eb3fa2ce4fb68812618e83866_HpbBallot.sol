pragma solidity ^0.4.24;

contract HpbBallot {
    
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
    string public name = "HpbBallot-2018-09-20";
    
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
    // Candidate struct
    struct Candidate{
        
        // 候选人账户地址
        // Candidate account address
        address candidateAddr;
        
        // 候选人名称
        // Name of candidate
        string name;
        
        // 候选者机器id(编号或者节点)
        // Candidate machine ID (node ID)
        bytes32 facilityId;
        
        // 保证金金额
        // bond
        uint balance;
        
        // 得票数
        // Number of votes
        uint numberOfVotes;
        
        //对候选者投票的投票者数组，用于遍历用途
        //An array of voters for the candidates to be used for traversal.
        address[] voterHistoryMapAddrs;
        
        // 已经投票了投票人账户地址-》投票数
        // The voting address of voters has been voted
        mapping (address => uint) voterHistoryMap;
        
    }
    
    // 投票结构体
    // Voting structure
    struct Voter{
        
        //投票人的账户地址
        //Address of voters
        address voterAddr;
        
        //投票人已经投票数
        //Voters have voted number.
        uint voteNumber;
        
        //用于遍历投票了的候选者用途
        //Candidate use for traversing voting
        address[] candidateHistoryMapAddrs;
        
        // 已经投票了的候选者账户地址-》投票数
        // The candidate&#39;s account address has been voted
        mapping (address => uint) candidateHistoryMap;
        
    }
    
    // 候选者的数组
    // An array of candidates
    Candidate[] public candidateArray;
    
    /*
     * 候选者的地址与以上变量候选者数组（candidateArray）索引(数组下标)对应关系,用于查询候选者用途
     * 这样可以降低每次遍历对象对gas的消耗，存储空间申请和申请次数远远小于查询次数，并且计票步骤更加复杂，相比较消耗gas更多
     * The address of the candidate corresponds to the index (array subscript) of 
     * the candidate array of variables above for the purpose of querying candidates
     * This reduces the consumption of gas for each traversal object, reduces the number of requests and requests for 
     * storage space far less than the number of queries,and makes the counting step more complex than consuming gas.
    */
    mapping (address => uint) public candidateIndexMap;
   
    // 候选者保证金最少金额，比如1000个HPB(10 ** 20)
    // Candidates minimum bond, such as 1000 HPB (10 * 20).
    uint public minAmount = 10 ** 20;
    
    //是否已经释放保证金
    //Has the bond been released?
    bool public hasReleaseAmount=false;
    
    //投票者数组
    // An array of voters
    Voter[] public voterArray;
    
    //最终获选者总数（容量，获选者数量上限）
    //the total number of final winners (capacity, the upper limit of the number of candidates selected)
    uint public capacity;
    
    // 投票者的地址与投票者序号（voterArray下标）对应关系，便于查询和减少gas消耗
    // The voter&#39;s address corresponds to the voter&#39;s ordinal number (voter Array subscript), making it easy to query and reduce gas consumption
    mapping (address => uint) public voterIndexMap;
    
    // 增加候选者
    // add candidate
    event CandidateAdded(address indexed candidateAddr,bytes32 indexed facilityId,uint serialNumber,string name);
    
    // 更新候选者
    // update candidate
    event CandidateUpdated(address indexed candidateAddr,bytes32 indexed facilityId,uint serialNumber,string name);
    
    // 投票
    // vote
    event doVoted(address indexed VoteAddr,address indexed candidateAddr,uint num,uint serialNumber);
    
    // 改变投票区间值,改变保证金最少金额,改变投票版本号
    // Change the voting interval, change the minimum amount of bond, and change the voting number.
    event ChangeOfBlocks(uint indexed version,uint startBlock, uint endBlock,uint minAmount,uint capacity);

    // 记录发送HPB的发送者地址和发送的金额
    // Record the sender address and the amount sent to send HPB.
    event receivedEther(address indexed sender, uint amount);

	//接受HPB转账
	//Accept HPB transfer
    function () payable  external{
       emit receivedEther(msg.sender, msg.value);
    }
    
   address public owner;
    
   /**
    * 只有HPB基金会账户（管理员）可以调用
    * Only the HPB foundation account (administrator) can call.
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
     * 构造函数 初始化投票智能合约的部分依赖参数
     */
    constructor(
        //开始投票的区块号
    	// `startBlock` specifies from which block our vote starts.
        uint _startBlock,
         
        //结束投票的区块号
        // `endBlock` specifies from which block our vote ends.
        uint _endBlock,
         
        //保证金最少金额
        //Candidates minimum bond
        uint _minAmount,
        
        //获选者总量
        //the total number of final winners
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
	        //Set the first position.
	        voterIndexMap[msg.sender]=0;
            voterArray.push(Voter(msg.sender,0,new address[](0)));
            
            candidateIndexMap[msg.sender]=0;
	        candidateArray.push(Candidate(msg.sender,&#39;0&#39;,&#39;0&#39;,0,0,new address[](0)));
            
	        emit ChangeOfBlocks(_version,startBlock,_endBlock,_minAmount,_capacity);
     }

   /**
     * 管理员修改投票智能合约的部分依赖参数
     * Administrators modify some dependent parameters of voting smart contracts.
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
     * The administrator starts the voting.
     */
    function endVote() onlyOwner public{
        endBlock = block.number;
    }
    /**
     * 只有投票开始后执行
     * Only after voting begins.
     */
    modifier onlyVoteAfterStart{
        require(block.number>= startBlock);
        _;
    }
    /**
     * 只有投票进行中执行
     * Only voting is carried out.
     */
    modifier onlyVoteInProgress{
        require(block.number>= startBlock);
        require(block.number<= endBlock);
        _;
    }

    /**
     * 只有投票结束前执行
     * Only before voting is finished
     */
    modifier onlyVoteBeforeEnd{
        require(block.number<= endBlock);
        _;
    }

    /**
     * 只有投票结束后执行
     * Only after voting is finished
     */
    modifier onlyVoteAfterEnd{
        require(block.number> endBlock);
        _;
    }

    /**
     *增加候选者  add Candidate 
     * 
     * @param _candidateAddr Candidate account address for return bond (HPB)
     * @param _facilityId 候选者机器设备号或者节点ID Candidate machine equipment number or node ID
     * @param _name 候选者名称  Candidate name
     * 
     */
    function addCandidate(
        address _candidateAddr,
        bytes32 _facilityId,
        string _name
    ) onlyOwner onlyVoteBeforeEnd public{
        uint index = candidateIndexMap[_candidateAddr];
        // 判断候选人是否已经存在 Judge whether candidates exist.
        if (index == 0) { // 如果没有，就添加  If not, add
            index = candidateArray.length;
            candidateIndexMap[_candidateAddr]=index;
	        candidateArray.push(Candidate(_candidateAddr,_name,_facilityId,0,0,new address[](0)));
	        emit CandidateAdded(_candidateAddr,_facilityId,index,_name);
        }
    }
    /**
     * 更新候选者 update Candidate 
     * @param _candidateAddr Candidate account address for return bond (HPB)
     * @param _facilityId 候选者机器设备号或者节点ID Candidate machine equipment number or node ID
     * @param _name 候选者名称  Candidate name
     * 
     */
    function updateCandidate(
        address _candidateAddr,
        bytes32 _facilityId,
        string _name
    ) onlyOwner onlyVoteBeforeEnd public{
        // 判断候选人是否已经存在 Judge whether candidates exist.
        require(candidateIndexMap[_candidateAddr] != 0);
        uint index = candidateIndexMap[_candidateAddr];
        candidateArray[index].facilityId=_facilityId;
        candidateArray[index].name=_name;
        emit CandidateUpdated(_candidateAddr,_facilityId,index,_name);
    }

    /**
     * 删除候选者 Delete Candidate 
     * @param _candidateAddr 候选者账户地址 Candidate account address
     */
    function deleteCandidates(
        address _candidateAddr
    ) onlyOwner onlyVoteBeforeEnd public{
        require(candidateIndexMap[_candidateAddr] != 0);
        
        /**
         * 删除候选者投票 Delete candidate vote
         */
        uint index=candidateIndexMap[_candidateAddr];
        for(uint n=0;n<candidateArray[index].voterHistoryMapAddrs.length;n++){
           //得到投票者 get voter
           uint voterIndex = voterIndexMap[candidateArray[index].voterHistoryMapAddrs[i]];
	       uint cindex=0;
	        for (uint k = 0;k<voterArray[voterIndex].candidateHistoryMapAddrs.length-1;k++){
	            if(voterArray[voterIndex].candidateHistoryMapAddrs[k]==_candidateAddr){
	                //得到候选者所处投票者结构体中的位置 Gets the position of the candidate in the structure of the voters.
	                cindex=k;
	            }
	            //如果投票者结构体中候选者存在 If the candidate in the voter structure is exist
	            if(cindex>0&&k>=cindex){
	                voterArray[voterIndex].candidateHistoryMapAddrs[k]=voterArray[voterIndex].candidateHistoryMapAddrs[k+1];
	            }
	        }
	        delete voterArray[voterIndex].candidateHistoryMapAddrs[voterArray[voterIndex].candidateHistoryMapAddrs.length-1];
	        voterArray[voterIndex].candidateHistoryMapAddrs.length--;
	        voterArray[voterIndex].candidateHistoryMap[_candidateAddr]=0;
        }
        
        for (uint i = index;i<candidateArray.length-1;i++){
            candidateArray[i] = candidateArray[i+1];
        }
        delete candidateArray[candidateArray.length-1];
        candidateArray.length--;
        candidateIndexMap[_candidateAddr]=0;
    }
    /**
     * 缴纳保证金 Payment bond
     */
    function payDepositByCandidate() onlyVoteBeforeEnd payable public{
        uint index = candidateIndexMap[msg.sender];
        // 判断候选人是否已经存在 Judge whether candidates exist.
        require(candidateIndexMap[msg.sender] != 0);
        uint balance=safeAdd(candidateArray[index].balance,msg.value);
        candidateArray[index].balance=balance;
    }
    /**
     * 用于非质押(锁定)投票多候选人 Multiple candidates for non pledge (locked) balloting
      */
    function multiVoteNoLock(
        address[] candidateAddrs,
    	uint[] nums
    )onlyVoteInProgress public {
        // 获取投票人的账户地址 Get the address of the voters.
        address voterAddr = msg.sender;
    	uint index=voterIndexMap[voterAddr];
    	
        if (index == 0) { // 如果从没投过票，就添加投票人 If you never cast a vote, you add voters.
            index =voterArray.length;
            voterIndexMap[voterAddr] =index;
            voterArray.push(Voter(voterAddr,0,new address[](0)));
        }
        
        uint[] memory _nums=calVote(voterAddr);
        //已经投票的总数量 Total number of votes already cast
        uint sum=0;
        for(uint i=0;i<_nums.length;i++){
            sum=safeAdd(sum,_nums[i]);
        }
        //必须有可投票数 There must be a number of votes available.
        require(voterAddr.balance>sum);
        
        for(uint k=0;k<nums.length;k++){
        	require(safeSub(voterAddr.balance,sum)>nums[k]);
        	sum=safeAdd(sum,nums[k]);
            doVote(candidateAddrs[k],index,nums[k]);
        }
        
	}
	/**
     * 撤回对多个候选人的投票 Multiple withdraw a vote on a candidate.
      */
	function multiCancelVoteForCandidate(
		address[] candidateAddrs,
    	uint[] nums
    ) onlyVoteInProgress public {
	    address voterAddr = msg.sender;
        uint index=voterIndexMap[voterAddr];
        //必须投过票 Tickets must be cast.
        require(index!=0);
        uint[] memory _nums=calVote(voterAddr);
        //已经投票的总数量 Total number of votes already cast
        uint sum=0;
        for(uint i=0;i<_nums.length;i++){
            sum=safeAdd(sum,_nums[i]);
        }
        require(voterArray[index].voteNumber>=sum);
        //必须已投候选者票数大于取消数量
        for(uint k=0;k<nums.length;k++){
            uint candidateIndex=candidateIndexMap[candidateAddrs[k]];
        	//候选人必须存在 Candidates must exist
        	require(candidateIndex!=0);
        	cancelVote(candidateAddrs[k],index,nums[k]);
        }
	}
	/**
     * 撤回对某个候选人的投票 Withdraw a vote on a candidate.
      */
	function cancelVoteForCandidate(
		address candidateAddr,
    	uint num
    ) onlyVoteInProgress public {
	    address voterAddr = msg.sender;
        require(voterAddr.balance>=num);
        uint index=voterIndexMap[voterAddr];
        //必须投过票 Tickets must be cast.
        require(index!=0);
        uint candidateIndex=candidateIndexMap[candidateAddr];
        //候选人必须存在 Candidates must exist
        require(candidateIndex!=0);
        
        cancelVote(candidateAddr,index,num);
	}
	function cancelVote(
        address candidateAddr,
        uint index,
    	uint num
    ) onlyVoteInProgress internal {
        //必须已投候选者票数大于取消数量
        uint cnum=voterArray[index].candidateHistoryMap[candidateAddr];
        require(cnum>=num);
        voterArray[index].candidateHistoryMap[candidateAddr]=safeSub(cnum,num);
    }
 	/**
     * 用于非质押(锁定)投票  For non locked voting
      */
    function  voteNoLock(
    	address candidateAddr,
    	uint num
    ) onlyVoteInProgress public {
        // 获取投票人的账户地址 Get the address of the voters.
        address voterAddr = msg.sender;
        
        require(voterAddr.balance>=num);
        
        uint index=voterIndexMap[voterAddr];
        if (index == 0) { // 如果从没投过票，就添加投票人 If you never cast a vote, you add voters.
            index =voterArray.length;
            voterIndexMap[voterAddr] =index;
            voterArray.push(Voter(voterAddr,0,new address[](0)));
        }
        uint[] memory _nums=calVote(voterAddr);
        //已经投票的总数量 Total number of votes already cast
        uint sum=0;
        for(uint i=0;i<_nums.length;i++){
            sum=safeAdd(sum,_nums[i]);
        }
        require(voterAddr.balance>sum);
        require(safeSub(voterAddr.balance,sum)>num);
        doVote(candidateAddr,index,num);
    }
    /**
     * 执行投票 do vote
      */
    function doVote(
        address candidateAddr,
        uint index,
    	uint num
    ) onlyVoteInProgress internal {
        require(num>0);
        //已经投票数 Number of votes already cast
        uint voteNumber=voterArray[index].voteNumber;
        
        uint bal=voterArray[index].voterAddr.balance;
        //剩余余额 Surplus balance
        uint cbal=safeSub(bal,voteNumber);
        
        require(cbal>=num);
            
        uint candidateIndex=candidateIndexMap[candidateAddr];
        //候选人必须存在 Candidates must exist
        require(candidateIndex!=0);
        // 必须缴纳足够的保证金 Sufficient deposit must be paid.
        require(candidateArray[candidateIndex].balance>=minAmount);
        
        // 获取候选人中的投票人信息，并重新记录投票数 Get the information of voters in the candidate and re record the number of votes.
        if(candidateArray[candidateIndex].voterHistoryMap[voterArray[index].voterAddr]==0)	{
            candidateArray[candidateIndex].voterHistoryMap[voterArray[index].voterAddr]=num;
        } else {
            candidateArray[candidateIndex].voterHistoryMap[voterArray[index].voterAddr]=
            safeAdd(candidateArray[candidateIndex].voterHistoryMap[voterArray[index].voterAddr],num);
        }
        bool hasVoterAddr=false;
        for (uint i = 1;i<candidateArray[candidateIndex].voterHistoryMapAddrs.length-1;i++){
            if(voterArray[index].voterAddr==candidateArray[candidateIndex].voterHistoryMapAddrs[i]){
                hasVoterAddr=true;
                break;
            }
	    }
	    if(!hasVoterAddr){
	        candidateArray[candidateIndex].voterHistoryMapAddrs.push(voterArray[index].voterAddr);
	        //uint vl=candidateArray[candidateIndex].voterHistoryMapAddrs.length;
	        //candidateArray[candidateIndex].voterHistoryMapAddrs.length=safeAdd(vl,1);
	        //candidateArray[candidateIndex].voterHistoryMapAddrs[vl]=voterAddr;
	    }
        
        
        voterArray[index].voteNumber=safeAdd(voteNumber,num);
        uint candidateNum=voterArray[index].candidateHistoryMap[candidateAddr];
        voterArray[index].candidateHistoryMap[candidateAddr]=safeAdd(candidateNum,num);
        
        if(voterArray[index].candidateHistoryMapAddrs.length==0){
            voterArray[index].candidateHistoryMapAddrs.push(candidateAddr);
            //uint cl=voterArray[index].candidateHistoryMapAddrs.length;
		    //voterArray[index].candidateHistoryMapAddrs.length=safeAdd(cl,1);
		    //voterArray[index].candidateHistoryMapAddrs[cl]=candidateAddr;
        }else{
            bool hasAddr=false;
            for (uint k = 1;k<voterArray[index].candidateHistoryMapAddrs.length-1;k++){
	            if(candidateAddr== voterArray[index].candidateHistoryMapAddrs[k]){
	                hasAddr=true;
	                break;
	            }
		    }
		    if(!hasAddr){
		        voterArray[index].candidateHistoryMapAddrs.push(candidateAddr);
		        //uint l=voterArray[index].candidateHistoryMapAddrs.length;
		        //voterArray[index].candidateHistoryMapAddrs.length=safeAdd(l,1);
		        //voterArray[index].candidateHistoryMapAddrs[l]=candidateAddr;
		    }
        }
        emit doVoted(voterArray[index].voterAddr,candidateAddr,num,candidateIndex);
    }
    
    /**
     * 释放保证金 Release bond
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
     * 计算候选者票数  Calculate the votes of candidates
     */
   function calCandidate(
        address _candidateAddr
    ) onlyVoteInProgress internal returns (
        uint[] nums
    ){
        uint candidateIndex = candidateIndexMap[_candidateAddr];
        uint[] memory _cnums=new uint[](candidateArray[candidateIndex].voterHistoryMapAddrs.length);
        for (uint i = 1;i<candidateArray[candidateIndex].voterHistoryMapAddrs.length-1;i++){
            address voterAddr=candidateArray[candidateIndex].voterHistoryMapAddrs[i];
            uint[] memory _nums=calVote(voterAddr);
            for (uint k = 1;k<_nums.length;i++){
                uint voterIndex=voterIndexMap[voterAddr];
                if(_candidateAddr==voterArray[voterIndex].candidateHistoryMapAddrs[k]){
                    _cnums[i]=_nums[k];
                    break;
                }
            }
        }
        return _cnums;
    }
   
    /**
     * 得到即时投票结果 Get instant results.
      */
    function voteCurrentResult(
    ) onlyVoteAfterStart public returns(
        address[] addr,
        bytes32[] facilityIds,
        uint[] nums
    ){ 
        return calResult();
    }
    
     function calResult(
    ) onlyVoteAfterStart internal returns(
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
             //即时更新得票情况，根据投票人的实际持币数量 Update the votes immediately according to the actual amount of hpb held by voters.
             if(!hasReleaseAmount){//还没释放保证金，就释放保证金 If bond is not released , then releasing the deposit.
	             if(candidateArray[i].balance>0){
	                 candidateArray[i].candidateAddr.transfer(candidateArray[i].balance);
	                 candidateArray[i].balance=0;
	             }
             }
             if(i<=capacity){
                 //先初始化获选者数量池 Initialize the number of pools selected first.
                 _addrs[i-1]=candidateArray[i].candidateAddr;
                 _facilityIds[i-1]=candidateArray[i].facilityId;
                 _nums[i-1]=fechVoteNum(candidateArray[i].candidateAddr);
                 //先记录获选者数量池中得票最少的记录 Record the number of votes selected in the pool.
                 if(_nums[i-1]<min){
                     min=_nums[i-1];
                     minIndex=i-1;
                 }
             }else{
               if(candidateArray[i].numberOfVotes==min){
                   //对于得票相同的，取持币数量多的为当选 For the same votes, the number of holding currencies is high.
                   if(candidateArray[i].candidateAddr.balance>_addrs[minIndex].balance){
                       _addrs[minIndex]=candidateArray[i].candidateAddr;
		               _facilityIds[minIndex]=candidateArray[i].facilityId;
		               _nums[minIndex]=fechVoteNum(candidateArray[i].candidateAddr);
                   }
               }else if(candidateArray[i].numberOfVotes>min){
              	   _addrs[minIndex]=candidateArray[i].candidateAddr;
	               _facilityIds[minIndex]=candidateArray[i].facilityId;
	               _nums[minIndex]=fechVoteNum(candidateArray[i].candidateAddr);
	               //重新记下最小得票者 Recount the smallest ticket winner
	               min=_nums[minIndex];
               }
             }
        }
        hasReleaseAmount=true;
        return (_addrs,_facilityIds,_nums);
    }
    /**
     * 得到最终投票结果 Get the final vote.
      */
    function voteResult(
    ) onlyVoteAfterEnd public returns(
        address[] addr,
        bytes32[] facilityIds,
        uint[] nums
    ){
        return calResult();
    }
    
    /**
     * 获取投票人的所有投票情况 Get all the votes of voters.
     */
    function fechVoteInfoForVoter(
    ) onlyVoteAfterStart public returns (
        address[] addrs,
        uint[] nums
    ){
        uint index = voterIndexMap[msg.sender];
        if(index==0){//没投过票 No vote
        	return (new address[](0),new uint[](0));
        }
        uint[] memory _nums=calVote(msg.sender);
        if(_nums.length==0){
           return (new address[](0),new uint[](0)); 
        }
        return (voterArray[index].candidateHistoryMapAddrs,_nums);
    }
    function calVote(
        address voterAddr
    ) onlyVoteInProgress internal returns (
        uint[] nums
    ){
        uint bal=voterAddr.balance;
        if(bal==0){
            return (new uint[](0));
        }else {
	        uint index = voterIndexMap[voterAddr];
	        if(index==0){//没投过票 No vote
            	return (new uint[](0));
	        }else{
		        uint[] memory _nums=new uint[](voterArray[index].candidateHistoryMapAddrs.length);
		        //已经投票数 Number of votes already cast
       			uint voteNumber=voterArray[index].voteNumber;
       			if(bal>voteNumber){
			        for (uint k = 0;i<voterArray[index].candidateHistoryMapAddrs.length-1;k++){
			            _nums[k]=voterArray[index].candidateHistoryMap[voterArray[index].candidateHistoryMapAddrs[k]];
			        }
       			}else{
       			    //如果余额小于已投票数，获取应该移除的票数 If the balance is less than the number of votes, the number of votes to be removed should be obtained.
       			    uint removeBal=bal-voterArray[index].voteNumber;
       			    voterArray[index].voteNumber=bal;
       			    for (uint i = 0;i<voterArray[index].candidateHistoryMapAddrs.length-1;i++){
       			        if(removeBal>0){//如果需要移除已投的票（置为无效的票数）If necessary, remove the votes cast (invalid ballot).
	       			        if(removeBal<=voterArray[index].candidateHistoryMap[voterArray[index].candidateHistoryMapAddrs[i]]){
	       			            _nums[i]=voterArray[index].candidateHistoryMap[voterArray[index].candidateHistoryMapAddrs[i]]-removeBal;
	       			        }else{//如果无效票数多于该候选人票，清除已投的票 If the number of invalid ballots exceeds that candidate&#39;s ticket, clear the vote.
	       			            _nums[i]=0;
	       			            //重新计算无效票数 Recalculate invalid ballots
	       			            removeBal=removeBal-voterArray[index].candidateHistoryMap[voterArray[index].candidateHistoryMapAddrs[i]];
	       			        }
       			        }else{
       			            _nums[i]=voterArray[index].candidateHistoryMap[voterArray[index].candidateHistoryMapAddrs[i]];
       			        }
			        }
       			}
			    return (_nums);
	        }
        }
    
    }
    /**
     * 获取候选人的总得票数 Total number of votes obtained from candidates
     */
    function fechVoteNumForCandidate(
    ) onlyVoteAfterStart public returns (
        uint num
    ){
        return fechVoteNum(msg.sender);
    }
    function fechVoteNum(
        address candidateAddr
    ) onlyVoteAfterStart public returns (
        uint num
    ){
        uint index = candidateIndexMap[candidateAddr];
        require(index>0);
        // 如果候选人存在,即时更新竞选情况 If candidates exist, update the campaign immediately.
        uint[] memory _nums=calCandidate(candidateAddr);
        uint sum=0;
        for(uint i=0;i<_nums.length;i++){
            sum=safeAdd(sum,_nums[i]);
        }
        return sum;
    }
    /**
     * 获取候选人的竞选详细情况，包括投票者 Obtain details of candidates&#39; campaign, including voters.
     */
    function fechVoteResultForCandidate(
    ) onlyVoteAfterStart internal returns (
        address[] addr,
        uint[] nums
    ){
        uint index = candidateIndexMap[msg.sender];
        require(index>0);
        // 如果候选人存在,即时更新竞选情况 If candidates exist, update the campaign immediately.
        uint[] memory _nums=calCandidate(msg.sender);
        return (candidateArray[index].voterHistoryMapAddrs,_nums);
    }
}