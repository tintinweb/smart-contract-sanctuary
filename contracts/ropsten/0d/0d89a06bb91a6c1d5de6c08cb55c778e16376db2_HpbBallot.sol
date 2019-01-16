pragma solidity ^0.4.25;

contract HpbBallot {
    uint256 constant public MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256 z){
        if (x>MAX_UINT256-y) {revert();}return x+y;
    }
    function safeSub(uint256 x, uint256 y) internal pure returns (uint256 z){
        if (x<y){revert();}return x-y;
    }
    function safeMul(uint256 x, uint256 y) internal pure returns (uint256 z){
        if (y== 0){return 0;}
        if (x>MAX_UINT256 / y) {revert();}
        return x*y;
    }
    // 票池名称
    // pool name
    string public name = "HpbBallot";
    // 合约开启区块号
    uint public openBlock = 0;
    // 合约关闭区块号
    uint public closeBlock = 0;
    // 当前票池的版本号
    // currrent pool version
    uint public version = 1;
    //选择总共几轮的数据作为选举结果，默认值为6，就是7轮数据的累计得票数为选举结果
    uint public round = 6;
    // 候选者的结构体
    // Candidate struct
    struct Candidate{
        // 候选人账户地址
        // Candidate account address
        address candidateAddr;
        // 得票数
        // Number of votes
        uint numberOfVotes;
        //对候选者投票的投票者数组，用于遍历用途
        //An array of voters for the candidates to be used for traversal.
        address[] voterMapAddrs;
        // 已经投票了投票人账户地址-》投票数
        // The voting address of voters has been voted
        mapping (address => uint) voterMap;
        
        mapping (address => uint) voterMapAddrsIndex;
    }
    // 投票结构体
    // Voting structure
    struct Voter{
        //投票人的账户地址
        //Address of voters
        address voterAddr;
        //快照余额
        //Snapshot balance
        uint snapshotBalance;
        //投票人已经投票数(实际投票数)
        //Voters have voted number.
        uint voteNumber;
        //用于遍历投票了的候选者用途
        //Candidate use for traversing voting
        address[] candidateMapAddrs;
        // 已经投票了的候选者账户地址-》投票数
        // The candidate&#39;s account address has been voted
        mapping (address => uint) candidateMap;
    }
    // 阶段投票结构体
    // Vote stage structure
    struct VoteStage{
        //阶段快照对应的区块号
        uint snapshotBlock;
        //设置阶段快照对应的区块号
        uint createSnapshotBlock;
        // 候选者的数组
	    // An array of candidates
	    Candidate[] candidateArray;
	    /*
	     * 候选者的地址与以上变量候选者数组（candidateArray）索引(数组下标)对应关系,用于查询候选者用途
	     * 这样可以降低每次遍历对象对gas的消耗，存储空间申请和申请次数远远小于查询次数，并且计票步骤更加复杂，相比较消耗gas更多
	     * The address of the candidate corresponds to the index (array subscript) of 
	     * the candidate array of variables above for the purpose of querying candidates
	     * This reduces the consumption of gas for each traversal object, reduces the number of requests and requests for 
	     * storage space far less than the number of queries,and makes the counting step more complex than consuming gas.
	    */
	    mapping (address => uint) candidateIndexMap;
	    //投票者数组
	    // An array of voters
	    Voter[] voterArray;
	    // 投票者的地址与投票者序号（voterArray下标）对应关系，便于查询和减少gas消耗
	    // The voter&#39;s address corresponds to the voter&#39;s ordinal number (voter Array subscript),
	    // making it easy to query and reduce gas consumption
	    mapping (address => uint) voterIndexMap;
    }
    //自动投票结构体，便于持续性投票功能
    struct AutoVote{
	    uint nextSnapshotBlock;
	    //是否自动投票
        bool hasAutoVote;
	    //投票者下一个轮次自动投票余额
	    mapping (address => uint) nextVoterBalance;
    }
    //分阶段投票
    VoteStage[] public voteStages;
    //阶段投票序号
    mapping (uint => uint) voteStageIndexMap;
    //当前阶段快照区块号
    uint public currentSnapshotBlock;
    
    AutoVote autoVote;
    
    mapping (address => string) public candidateNameMap;
    mapping (address => string) public candidateFacilityMap;

    //最终选举出的候选人，便于查询
    uint[] public candidateIndexArray;
    //最终获选者总数（容量，获选者数量上限）
    //the total number of final winners (capacity, the upper limit of the number of candidates selected)
    uint public capacity;
    
    modifier onlyAutoVoteAfter{
        require(autoVote.hasAutoVote == true);
        _;
    }
    // 增加候选者
    // add candidate
    event CandidateAdded(address indexed candidateAddr,string indexed facility,string name);
    // 更新候选者
    // update candidate
    event CandidateUpdated(address indexed candidateAddr,string facility,string name);
    
    // 删除候选者
    // delete candidate
    event CandidateDeleted(address indexed candidateAddr);
    // 投票
    // vote
    event DoVoted(uint indexed index ,address indexed voteAddr,address indexed candidateAddr,uint num,uint flag);
    // 改变投票区间值,改变保证金最少金额,改变投票版本号
    // Change the voting interval and change the voting number.
    event UpdateContract(uint indexed version,uint openBlock, uint closeBlock,uint capacity);
    //更新阶段轮次
    event ChangeStageBlock(uint indexed preStageBlock,uint indexed stageBlock);
    //设置快照余额
    event SetSnapshotBalance(uint indexed voteStageIndex,address indexed voterAddr,uint _snapshotBalance);
	//投票和撤销投票日志，0撤销，1投票
 	event VoteNoLockByAdminInvokeDoVoted(address voterAddr,address candidateAddr,uint num);
    // 记录发送HPB的发送者地址和发送的金额
    // Record the sender address and the amount sent to send HPB.
    event ReceivedHpb(address indexed sender, uint amount);
	//接受HPB转账
	//Accept HPB transfer
    function () payable  external{
       emit ReceivedHpb(msg.sender, msg.value);
    }
   //对投票者设置快照余额的管理员
   //Administrators who set up snapshot balances for voters
   mapping (address => address) public adminMap;
   //必须是管理员才能设置快照余额
   //The snapshot administrator must set the snapshot balance.
   modifier onlyAdmin{
        require(adminMap[msg.sender] != 0);
        _;
   }
   //重置已自动投票状态，便于继续投票
   function resetHasAutoVote() onlyAdmin public{
        autoVote.hasAutoVote=true;
        autoVote.nextSnapshotBlock=0;
   }
   //增加普通管理员（管理合约，比如设置快照余额权利）
   function addAdmin(address addr) onlyOwner public{
        require(adminMap[addr]== 0);
        adminMap[addr] = addr;
   }
   //删除普通管理员
   function deleteAdmin(address addr) onlyOwner public{
        require(adminMap[addr] != 0);
        adminMap[addr]=0;
   }
   //设置选举结果的截止轮数（经过几轮投票就可出选举结果）
   function setRound(uint _round) onlyOwner public{
        uint _voteStageIndex=voteStageIndexMap[currentSnapshotBlock];
        require(_round>_voteStageIndex);
        round=_round;
   }
   //HPB首席管理员(可以基金会掌握)
   address public owner;
   /**
    * 只有HPB首席管理员可以调用
    * Only the HPB foundation account (administrator) can call.
   */
    modifier onlyOwner{
        require(msg.sender == owner);
        // Do not forget the "_;"! It will be replaced by the actual function
        // body when the modifier is used.
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public{
        owner = newOwner;
    }
    /**
     * 开启合约
     */
    function toOpenVote() onlyOwner public{
        openBlock = block.number;
    }
    /**
     * 关闭合约
     */
    function toCloseVote() onlyOwner public{
        closeBlock = block.number;
    }
    /**
     * 只有合约开启的时间后执行
     * Only after voting begins.
     */
    modifier onlyVoteAfterOpen{
        require(block.number>= openBlock);
        _;
    }
    /**
     * 只合约开启中执行
     * Only voting is carried out.
     */
    modifier onlyVoteInProgress{
        require(block.number>= openBlock);
        require(block.number<= closeBlock);
        _;
    }
     /**
     * Constructor function
     * 构造函数 初始化投票智能合约的部分依赖参数
     */
    constructor(
        //开启合约的区块号
    	// `openBlock` specifies from which block our vote starts.
        uint _openBlock,
        //关闭合约的区块号
        // `closeBlock` specifies from which block our vote ends.
        uint _closeBlock,
        //获选者总量
        //the total number of final winners
        uint _capacity,
        //当前票池的版本号
        //currrent pool version
        uint _version
     ) payable public{
            require(_openBlock< _closeBlock);
         	owner = msg.sender;
	        openBlock= _openBlock;
	        closeBlock= _closeBlock;
	        capacity=_capacity;
	        version=_version;
	        //设置默认普通管理员（合约创建者）
	        adminMap[owner]=owner;
			//设置默认的阶段block
			currentSnapshotBlock=_openBlock;
	        voteStages.length++;
	        voteStageIndexMap[currentSnapshotBlock]=0;
	        voteStages[0].snapshotBlock=currentSnapshotBlock;
			voteStages[0].createSnapshotBlock=block.number;
	        voteStages[0].voterIndexMap[msg.sender]=0;
	        //设置第一个位置（为了定位不出错，第一个位置不占用）
	        //Set the first position.
            voteStages[0].voterArray.push(
                Voter(msg.sender,0,0,new address[](0))
            );
            voteStages[0].candidateIndexMap[msg.sender]=0;
	        //设置第一位置（为了定位不出错，第一个位置不占用）
	        //Set the first position.
	        voteStages[0].candidateArray.push(
	            Candidate(msg.sender,0,new address[](0))
	        );
	        autoVote.hasAutoVote=true;
            autoVote.nextSnapshotBlock=0;
	        emit UpdateContract(_version,openBlock,_closeBlock,_capacity);
     }
   /**
     * 首席管理员修改投票智能合约的部分初始参数
     * Administrators modify some dependent parameters of voting smart contracts.
     */
    function updateContract(
        uint _openBlock,
        uint _closeBlock,
        uint _capacity,
        uint _version
    ) onlyOwner public{
        require(_openBlock< _closeBlock);
        openBlock = _openBlock;
        closeBlock = _closeBlock;
        capacity = _capacity;
        version = _version;
        emit UpdateContract(_version,_openBlock, _closeBlock,_capacity);
    }
    function setCapacity(
        uint _capacity
    ) onlyOwner public{
        capacity = _capacity;
    }
    function setOpenBlock(
        uint _openBlock
    ) onlyOwner public{
        require(_openBlock< closeBlock);
        openBlock = _openBlock;
    }
    function setCloseBlock(
        uint _closeBlock
    ) onlyOwner public{
        require(openBlock< _closeBlock);
        closeBlock = _closeBlock;
    }
 	/**
     * 更新阶段轮次
     */
    function changeStageBlock(
    ) onlyVoteAfterOpen onlyAutoVoteAfter onlyAdmin public{
        require(autoVote.nextSnapshotBlock!=0);
        uint _snapshotBlock=autoVote.nextSnapshotBlock;
        require(currentSnapshotBlock< _snapshotBlock);
        //获取当前阶段（轮次）区块号的位置（序号）
        uint _voteStageIndex=voteStageIndexMap[currentSnapshotBlock];
        //设置当前区块号为参数_snapshotBlock的值
        currentSnapshotBlock=_snapshotBlock;
        voteStages.length++;
	    _voteStageIndex=_voteStageIndex+1;
	    voteStageIndexMap[currentSnapshotBlock]=_voteStageIndex;
        voteStages[_voteStageIndex].snapshotBlock=currentSnapshotBlock;
        voteStages[_voteStageIndex].createSnapshotBlock=block.number;
        voteStages[_voteStageIndex].voterIndexMap[msg.sender]=0;
        //设置第一位置
	    //Set the first position.
        voteStages[_voteStageIndex].voterArray.push(
            Voter(msg.sender,0,0,new address[](0))
        );
	    //复制选出的候选者
        if(_voteStageIndex>round){
            voteResult();
            //奖励阶段轮次
            require(candidateIndexArray.length>0);
	        //设置第一位置
		    //Set the first position.
            voteStages[_voteStageIndex].candidateArray.push(
                Candidate(msg.sender,0,new address[](0))
            );
        	voteStages[_voteStageIndex].candidateIndexMap[msg.sender]=0;
        	
	        for(uint m=0;m<candidateIndexArray.length;m++){
	        	 voteStages[_voteStageIndex].candidateArray.push(
	        	     Candidate(
	        	         voteStages[0].candidateArray[candidateIndexArray[m]].candidateAddr,
	        	         0,new address[](0)
	        	 	 )
	        	 );
	        	 voteStages[_voteStageIndex].candidateIndexMap[
	        	     voteStages[0].candidateArray[candidateIndexArray[m]].candidateAddr
	        	 ]=safeAdd(m,1);
	        	 voteStages[_voteStageIndex].candidateArray[
	        	     safeAdd(m,1)
	        	 ].voterMapAddrs.push(msg.sender);
	        }
        }else{
            //竞选阶段轮次
            for(uint k=0;k<voteStages[0].candidateArray.length;k++){
	        	 voteStages[_voteStageIndex].candidateArray.push(
	        	     Candidate(
	        	         voteStages[0].candidateArray[k].candidateAddr,
	        	         0,new address[](0)
	        	 	 )
	        	 );
	        	 voteStages[_voteStageIndex].candidateIndexMap[
	        	     voteStages[0].candidateArray[k].candidateAddr
	        	 ]=k;
	        	 voteStages[_voteStageIndex].candidateArray[k].voterMapAddrs.push(msg.sender);
	        }
        }
        autoVote.hasAutoVote=false;
        voteNoLockByAdmin();
        emit ChangeStageBlock(voteStages[_voteStageIndex-1].snapshotBlock,_snapshotBlock);
    }
    function setNextSnapshotBlock(
       uint nextSnapshotBlock
    ) onlyAdmin onlyVoteAfterOpen onlyAutoVoteAfter public{
        autoVote.nextSnapshotBlock=nextSnapshotBlock;
        uint voteStageIndex=voteStageIndexMap[currentSnapshotBlock];
       
        require(voteStages[voteStageIndex].voterArray.length>1);
        uint cl=voteStages[voteStageIndex].voterArray.length;
       
        for(uint i=1;i<cl;i++){
           autoVote.nextVoterBalance[voteStages[voteStageIndex].voterArray[i].voterAddr]=
           voteStages[voteStageIndex].voterArray[i].voterAddr.balance;
        }
    }
    function getNextSnapshotBlock(
    ) onlyAdmin onlyVoteAfterOpen onlyAutoVoteAfter public constant returns (
        uint nextSnapshotBlock
    ){
        return autoVote.nextSnapshotBlock;
    }
    /**
     *增加候选者  add Candidate 
     * 
     * @param _candidateAddr Candidate account address for return bond (HPB)
     * @param _facility 候选者机器设备号或者节点ID Candidate machine equipment number or node ID
     * @param _name 候选者名称  Candidate name
     * 
     */
    function addCandidate(
        address _candidateAddr,
        string _facility,
        string _name
    ) onlyAdmin onlyVoteAfterOpen public{
        //必须首轮才可以添加候选人
        require(voteStageIndexMap[currentSnapshotBlock]==0);
        uint index = voteStages[0].candidateIndexMap[_candidateAddr];
        //必须候选人地址还未使用
        require(index == 0);
        //添加候选人
        index = voteStages[0].candidateArray.length;
        voteStages[0].candidateIndexMap[_candidateAddr]=index;
        voteStages[0].candidateArray.push(
            Candidate(_candidateAddr,0,new address[](0))
        );
        voteStages[0].candidateArray[index].voterMapAddrs.push(msg.sender);
        candidateNameMap[_candidateAddr]=_name;
        candidateFacilityMap[_candidateAddr]=_facility;
        emit CandidateAdded(_candidateAddr,_facility,_name);
    }
    function addCandidateBatch(
        address[] _candidateAddrs
    ) onlyAdmin onlyVoteAfterOpen public{
        for(uint i=0;i<_candidateAddrs.length;i++){
            addCandidate(_candidateAddrs[i],"","");
        }
    }
    /**
     * 更新候选者 update Candidate 
     * @param _candidateAddr Candidate account address for return bond (HPB)
     * @param _facility 候选者机器设备号或者节点ID Candidate machine equipment number or node ID
     * @param _name 候选者名称  Candidate name
     * 
     */
    function updateCandidate(
        address _candidateAddr,
        string _facility,
        string _name
    ) onlyOwner onlyVoteAfterOpen public{
        candidateNameMap[_candidateAddr]=_name;
        candidateFacilityMap[_candidateAddr]=_facility;
        emit CandidateUpdated(_candidateAddr,_facility,_name);
    }
    
    /**
     * 根据阶段删除候选者
     * @param _candidateAddr 候选者账户地址 Candidate account address
     * @param _snapshotBlock 阶段号
     */
    function deleteCandidateBySnapshotBlock(
        address _candidateAddr,
        uint _snapshotBlock
    ) onlyOwner onlyVoteAfterOpen internal{
        uint voteStageIndex=voteStageIndexMap[_snapshotBlock];
        if(voteStageIndex==0){
            require(_snapshotBlock==voteStages[0].snapshotBlock);
        }
        uint index=voteStages[voteStageIndex].candidateIndexMap[_candidateAddr];
        require(index!= 0);
        //删除该候选者对应的投票者关联的候选者信息
        for(uint n=1;n<voteStages[voteStageIndex].candidateArray[index].voterMapAddrs.length;n++){
           //得到投票者 get voter
           uint voterIndex = voteStages[voteStageIndex].voterIndexMap[
               voteStages[voteStageIndex].candidateArray[index].voterMapAddrs[n]
           ];
	       uint cindex=0;
	       //遍历对应投票者里面的候选者信息，并删除其中对应的该候选者
	       for(uint k=1;k<voteStages[voteStageIndex].voterArray[
	           voterIndex
	       ].candidateMapAddrs.length-1;k++){
	            if(voteStages[voteStageIndex].voterArray[
	                voterIndex
	            ].candidateMapAddrs[k]==_candidateAddr){
	                //得到候选者所处投票者结构体中的位置
	                // Gets the position of the candidate in the structure of the voters.
	                cindex=k;
	            }
	            //如果投票者结构体中候选者存在 If the candidate in the voter structure is exist
	            if(cindex>0&&k>=cindex){
	                voteStages[voteStageIndex].voterArray[voterIndex].candidateMapAddrs[k]=
	                voteStages[voteStageIndex].voterArray[voterIndex].candidateMapAddrs[k+1];
	            }
	        }
	        //撤回已经投的票
	        voteStages[voteStageIndex].voterArray[voterIndex].voteNumber=safeSub(
	            voteStages[voteStageIndex].voterArray[voterIndex].voteNumber,
	            voteStages[voteStageIndex].voterArray[voterIndex].candidateMap[_candidateAddr]
	        );
	        voteStages[voteStageIndex].voterArray[voterIndex].candidateMap[_candidateAddr]=0;
	        
	        delete voteStages[voteStageIndex].voterArray[voterIndex].candidateMapAddrs[
	            voteStages[voteStageIndex].voterArray[voterIndex].candidateMapAddrs.length-1
	        ];
	        voteStages[voteStageIndex].voterArray[voterIndex].candidateMapAddrs.length--;
        }
        for (uint i = index;i<voteStages[voteStageIndex].candidateArray.length-1;i++){
            voteStages[voteStageIndex].candidateArray[i] = voteStages[voteStageIndex].candidateArray[i+1];
        }
        delete voteStages[voteStageIndex].candidateArray[
            voteStages[voteStageIndex].candidateArray.length-1
        ];
        voteStages[voteStageIndex].candidateArray.length--;
        voteStages[voteStageIndex].candidateIndexMap[_candidateAddr]=0;
        emit CandidateDeleted(_candidateAddr);
    }
    /**
     * 删除候选者 Delete Candidate 
     * @param _candidateAddr 候选者账户地址 Candidate account address
     */
    function deleteCandidates(
        address _candidateAddr
    ) onlyOwner onlyVoteAfterOpen public{
        deleteCandidateBySnapshotBlock(_candidateAddr,currentSnapshotBlock);
    }
    function deleteCandidatesBatch(
        address[] _candidateAddrs
    ) onlyOwner onlyVoteAfterOpen public{
        for(uint i=0;i<_candidateAddrs.length;i++){
            deleteCandidates(_candidateAddrs[i]);
        }
    }
	/**
     * 撤回指定阶段对某个候选人的投票 Withdraw a vote on a candidate.
      */
	function cancelVoteForCandidateBySnapshotBlock(
		address candidateAddr,
    	uint num,
    	uint _snapshotBlock
    ) onlyVoteAfterOpen internal {
	    address voterAddr = msg.sender;
	    uint voteStageIndex=voteStageIndexMap[_snapshotBlock];
        if(voteStageIndex==0){
            require(_snapshotBlock==voteStages[0].snapshotBlock);
        }
        uint index=voteStages[voteStageIndex].voterIndexMap[voterAddr];
        //必须投过票 Tickets must be cast.
        require(index!=0);
        uint candidateIndex=voteStages[voteStageIndex].candidateIndexMap[candidateAddr];
        //候选人必须存在 Candidates must exist
        require(candidateIndex!=0);
        //必须已投候选者票数不少于取消数量
        uint cnum=voteStages[voteStageIndex].voterArray[index].candidateMap[candidateAddr];
        require(cnum>=num);
        //处理候选者中的投票信息
        voteStages[voteStageIndex].candidateArray[candidateIndex].voterMap[voterAddr]=safeSub(cnum,num);
        voteStages[voteStageIndex].candidateArray[candidateIndex].numberOfVotes=safeSub(
            voteStages[voteStageIndex].candidateArray[candidateIndex].numberOfVotes,num
        );
        //处理投票者里面的投票信息
        voteStages[voteStageIndex].voterArray[index].candidateMap[candidateAddr]=safeSub(cnum,num);
        voteStages[voteStageIndex].voterArray[index].voteNumber=safeSub(
            voteStages[voteStageIndex].voterArray[index].voteNumber,num
        );
        //该操作后，下一轮就不能自动投票
        emit DoVoted(voteStageIndex,voterAddr,candidateAddr,num,0);
	}
	/**
     * 撤回当前阶段对某个候选人的投票 Withdraw a vote on a candidate.
      */
	function cancelVoteForCandidate(
		address candidateAddr,
    	uint num
    ) onlyVoteAfterOpen public {
        return cancelVoteForCandidateBySnapshotBlock(candidateAddr,num,currentSnapshotBlock);
    }
    /**
     * 设置投票人的快照余额（以指定的区块号为准，到时候由官方或者HPB基金会对外公布）
     * Set the voter&#39;s snapshot balance (subject to the designated block number, 
     * to be published by the official or HPB Foundation)
      */
    function  setSnapshotBalance(
    	address voterAddr,
    	uint _snapshotBalance
    )onlyAdmin onlyVoteAfterOpen public {
        require(_snapshotBalance>0);
        uint voteStageIndex=voteStageIndexMap[currentSnapshotBlock];
        uint index=voteStages[voteStageIndex].voterIndexMap[voterAddr];
        if (index == 0) { // 如果从没投过票，就添加投票人 If you never cast a vote, you add voters.
            index =voteStages[voteStageIndex].voterArray.length;
            voteStages[voteStageIndex].voterIndexMap[voterAddr] =index;
            voteStages[voteStageIndex].voterArray.push(
                Voter(voterAddr,_snapshotBalance,0,new address[](0))
            );
            voteStages[voteStageIndex].voterArray[index].candidateMapAddrs.push(msg.sender);
        }else{
            voteStages[voteStageIndex].voterArray[index].snapshotBalance=_snapshotBalance;
        }
        emit SetSnapshotBalance(voteStageIndex,voterAddr,_snapshotBalance);
    }
    function  setNextSnapshotBalance(
    	address voterAddr,
    	uint _snapshotBalance
    )onlyAdmin onlyVoteAfterOpen public {
        require(_snapshotBalance>0);
        require(autoVote.nextSnapshotBlock!=0);
        require(autoVote.nextVoterBalance[voterAddr]!=_snapshotBalance);
        autoVote.nextVoterBalance[voterAddr]=_snapshotBalance;
    }
    function  setCurrentAndNextSnapshotBalance(
    	address voterAddr,
    	uint _csnapshotBalance,
    	uint _nsnapshotBalance
    )onlyAdmin onlyVoteAfterOpen public {
        setSnapshotBalance(voterAddr,_csnapshotBalance);
        setNextSnapshotBalance(voterAddr,_nsnapshotBalance);
    }
    
    /**
     * 用于自动投票，根据前一个轮次的投票记录程序自动投票
      */
    function  voteNoLockByAdmin(
    )onlyAdmin onlyVoteAfterOpen internal {
        uint voteStageIndex=voteStageIndexMap[currentSnapshotBlock];
        require(voteStageIndex != 0);
        uint stageIndex=voteStageIndex-1;
        require(voteStages[stageIndex].voterArray.length>1);
        uint cl=voteStages[stageIndex].voterArray.length;
       
        for(uint i=1;i<cl;i++){
           uint bl=autoVote.nextVoterBalance[voteStages[stageIndex].voterArray[i].voterAddr];
           uint voteNumber=voteStages[stageIndex].voterArray[i].voteNumber;
           if(bl>0&&voteNumber>0){   
               uint proportion=100000;
               if(voteNumber>bl){
                   proportion=safeMul(bl,proportion)/voteNumber;
               }
               setSnapshotBalance(voteStages[stageIndex].voterArray[i].voterAddr,bl);
               uint vvcl=voteStages[stageIndex].voterArray[i].candidateMapAddrs.length;
               for(uint k = 1;k<vvcl;i++){
                    uint _num=voteStages[stageIndex].voterArray[i].candidateMap[
                        voteStages[stageIndex].voterArray[i].candidateMapAddrs[k]
                    ];
                    uint num=safeMul(_num,proportion)/100000;
                    if(num>10000000000){
                        address _addr=voteStages[stageIndex].voterArray[i].candidateMapAddrs[k];
                        emit VoteNoLockByAdminInvokeDoVoted(voteStages[stageIndex].voterArray[i].voterAddr
                        ,_addr,num);
                        doVote(_addr,voteStageIndex,num);
                    }
                }
           }
        }
        resetHasAutoVote();
    }
    
 	/**
     * 用于非质押(锁定)投票  For non locked voting
      */
    function  voteNoLock(
    	address candidateAddr,
    	uint num
    ) onlyVoteAfterOpen onlyAutoVoteAfter public {
        // 获取投票人的账户地址 Get the address of the voters.
        address voterAddr = msg.sender;
        //防止投票短地址攻击
        require(voterAddr!=0);
        require(candidateAddr!=0);
        uint voterAddrSize;
		assembly {voterAddrSize := extcodesize(voterAddr)}
		require(voterAddrSize==0);
        uint candidateAddrSize;
		assembly {candidateAddrSize := extcodesize(candidateAddr)}
		require(candidateAddrSize==0);
        uint voteStageIndex=voteStageIndexMap[currentSnapshotBlock];
        uint index=voteStages[voteStageIndex].voterIndexMap[voterAddr];
        //必须设置过快照
        require(index != 0);
        //剩余的可投票数必须不少于投票数
        require(safeSub(
            voteStages[voteStageIndex].voterArray[index].snapshotBalance,
            voteStages[voteStageIndex].voterArray[index].voteNumber
        )>=num);
        doVote(candidateAddr,index,num);
    }
    /**
     * 用于批量非质押(锁定)投票  For non locked voting
      */
    function  voteNoLockBatch(
    	address[] candidateAddrs,
    	uint[] nums
    ) onlyVoteAfterOpen public {
        for(uint i=0;i<candidateAddrs.length;i++){
            voteNoLock(candidateAddrs[i],nums[i]);
        }
    }
    /**
     * 执行投票 do vote
      */
    function doVote(
        address candidateAddr,
        uint index,
    	uint num
    ) onlyVoteAfterOpen internal {
        require(num>0);
        uint voteStageIndex=voteStageIndexMap[currentSnapshotBlock];
        uint candidateIndex=voteStages[voteStageIndex].candidateIndexMap[candidateAddr];
        //候选人必须存在 Candidates must exist
        require(candidateIndex!=0);
        if(voteStages[voteStageIndex].candidateArray[candidateIndex].voterMapAddrsIndex[
            	voteStages[voteStageIndex].voterArray[index].voterAddr
        	]<1){ 
        	voteStages[voteStageIndex].candidateArray[candidateIndex].voterMapAddrsIndex[
            	voteStages[voteStageIndex].voterArray[index].voterAddr
        	]=1;   
            voteStages[voteStageIndex].candidateArray[candidateIndex].voterMapAddrs.push(
	            voteStages[voteStageIndex].voterArray[index].voterAddr
	        );
	        voteStages[voteStageIndex].candidateArray[candidateIndex].voterMap[
	            voteStages[voteStageIndex].voterArray[index].voterAddr
	        ]=num;
	        
	        voteStages[voteStageIndex].voterArray[index].candidateMapAddrs.push(candidateAddr);
	        voteStages[voteStageIndex].voterArray[index].candidateMap[candidateAddr]=num;
        }else{
	        voteStages[voteStageIndex].candidateArray[candidateIndex].voterMap[
	            voteStages[voteStageIndex].voterArray[index].voterAddr
	        ]=safeAdd(voteStages[voteStageIndex].candidateArray[candidateIndex].voterMap[
	            voteStages[voteStageIndex].voterArray[index].voterAddr
	        ],num);
	        voteStages[voteStageIndex].voterArray[index].candidateMap[candidateAddr]=safeAdd(
	            voteStages[voteStageIndex].voterArray[index].candidateMap[candidateAddr],num
	        );
        }
        //投票人已投总数累加
        voteStages[voteStageIndex].voterArray[index].voteNumber=safeAdd(
            voteStages[voteStageIndex].voterArray[index].voteNumber,num
        );
	    //候选者得票数累加
        voteStages[voteStageIndex].candidateArray[candidateIndex].numberOfVotes=safeAdd(
            voteStages[voteStageIndex].candidateArray[candidateIndex].numberOfVotes,num
        );
        emit DoVoted(voteStageIndex,voteStages[voteStageIndex].voterArray[index].voterAddr,candidateAddr,num,1);
    }   
    /**
     * string类型转换成bytes32类型
      */
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
       assembly {
        result := mload(add(source, 32))
      }
    }
    /**
     * 获取指定阶段所有候选人的详细信息
     * Get detailed information about all candidates.
      */
    function fechAllCandidatesBySnapshotBlock(
        uint _snapshotBlock
    ) onlyVoteAfterOpen public constant returns (
        address[] addrs,
        bytes32[] names,
        bytes32[] facilitys
    ){
        uint voteStageIndex=voteStageIndexMap[_snapshotBlock];
        if(voteStageIndex==0){
            require(_snapshotBlock==voteStages[0].snapshotBlock);
        }
        require(voteStages[voteStageIndex].candidateArray.length>1);
        uint cl=voteStages[voteStageIndex].candidateArray.length-1;
        address[] memory _addrs=new address[](cl);
        bytes32[] memory _names=new bytes32[](cl);
        bytes32[] memory _facilitys=new bytes32[](cl);
        for(uint i=1;i<=cl;i++){
            _addrs[i-1]=voteStages[voteStageIndex].candidateArray[i].candidateAddr;
            _names[i-1]=stringToBytes32(
                candidateNameMap[_addrs[i-1]]
            );
            _facilitys[i-1]=stringToBytes32(
                candidateFacilityMap[_addrs[i-1]]
            );
        }
        return (_addrs,_names,_facilitys);
    }
    /**
     * 获取指定阶段所有投票人的详细信息
     * 
      */
    function fechAllVotersBySnapshotBlock(
        uint _snapshotBlock
    ) onlyVoteAfterOpen public constant returns (
        address[] voterAddrs,
        uint[] snapshotBalances,
        uint[] voteNumbers
    ){
        uint voteStageIndex=voteStageIndexMap[_snapshotBlock];
        if(voteStageIndex==0){
            require(_snapshotBlock==voteStages[0].snapshotBlock);
        }
        require(voteStages[voteStageIndex].voterArray.length>1);
        uint cl=voteStages[voteStageIndex].voterArray.length-1;
        address[] memory _addrs=new address[](cl);
        uint[] memory _snapshotBalances=new uint[](cl);
        uint[] memory _voteNumbers=new uint[](cl);
        for(uint i=1;i<=cl;i++){
            _addrs[i-1]=voteStages[voteStageIndex].voterArray[i].voterAddr;
            _snapshotBalances[i-1]=voteStages[voteStageIndex].voterArray[i].snapshotBalance;
            _voteNumbers[i-1]=voteStages[voteStageIndex].voterArray[i].voteNumber;
        }
        return (_addrs,_snapshotBalances,_voteNumbers);
    }
    /**
     * 得到最终投票选举结果 ,必须在调用voteResult后执行
     * 该方法为常量方法，可以通过消息调用，如果更新了地址，返回的是更新的地址数据
      */
    function getVoteResult(
    ) onlyVoteAfterOpen public constant returns(
        address[] addr,
        bytes32[] facilitys,
        uint[] nums
    ){
        uint cl=candidateIndexArray.length;
        address[] memory _addrs=new address[](cl);
        bytes32[] memory _facilitys=new bytes32[](cl);
        uint[] memory _nums=new uint[](cl);
        for(uint m=0;m<cl;m++){
             _addrs[m]=voteStages[round].candidateArray[candidateIndexArray[m]].candidateAddr;
             
             _facilitys[m]=stringToBytes32(candidateFacilityMap[_addrs[m]]);
             _nums[m]=voteStages[round].candidateArray[candidateIndexArray[m]].numberOfVotes;
        }
        return (_addrs,_facilitys,_nums);
    }
    /**
     * 得到最终投票选举结果 Get the final vote.
      */
    function voteResult(
    ) onlyVoteAfterOpen public returns(
        address[] addr,
        bytes32[] facilitys,
        uint[] nums
    ){
        uint _stageIndex=voteStageIndexMap[currentSnapshotBlock];
        //必须竞选轮次后调用
        require(_stageIndex>round);
        if(candidateIndexArray.length>0){
            return getVoteResult();
         }else{
             require(voteStages[round].candidateArray.length>1);
             uint vcl=voteStages[round].candidateArray.length-1;
             Candidate[] memory _candidates=new Candidate[](vcl);
             //取得第round轮的数据作为选举池
             for (uint i = 1;i<=vcl;i++){
                 _candidates[i-1]=Candidate(
                     voteStages[round].candidateArray[i].candidateAddr,
                     voteStages[round].candidateArray[i].numberOfVotes,
                     new address[](0)
                 );
             }
        	return calVoteResult(_candidates);
         }
    }
    /**
     * 计算选举结果
      */
    function calVoteResult(
        Candidate[] memory _candidates
    ) onlyVoteAfterOpen internal returns(
        address[] addr,
        bytes32[] facilitys,
        uint[] nums
    ){
         require(capacity<=_candidates.length);
         address[] memory _addrs=new address[](capacity);
         bytes32[] memory _facilitys=new bytes32[](capacity);
         uint[] memory _nums=new uint[](capacity);
         uint min=_candidates[0].numberOfVotes;
         uint minIndex=0;
         for (uint p = 0;p<_candidates.length;p++){
             if(p<capacity){
                 //先初始化获选者数量池 Initialize the number of pools selected first.
                 _addrs[p]=_candidates[p].candidateAddr;
                 _facilitys[p]=stringToBytes32(candidateFacilityMap[_addrs[p]]);
                 _nums[p]=_candidates[p].numberOfVotes;
                 //先记录获选者数量池中得票最少的记录 Record the number of votes selected in the pool.
                 if(_nums[p]<min){
                     min=_nums[p];
                     minIndex=p;
                 }
             }else{
               if(_candidates[p].numberOfVotes==min){
                   //对于得票相同的，取持币数量多的为当选
                   /**
                    * if(_candidates[p].candidateAddr.balance>_addrs[minIndex].balance){
                       _addrs[minIndex]=_candidates[p].candidateAddr;
		               _facilitys[minIndex]=stringToBytes32(candidateFacilityMap[_addrs[p]]);
		               _nums[minIndex]=_candidates[p].numberOfVotes;
                   }
                   */
               }else if(_candidates[p].numberOfVotes>min){
              	   _addrs[minIndex]=_candidates[p].candidateAddr;
	               _facilitys[minIndex]=stringToBytes32(candidateFacilityMap[_addrs[p]]);
	               _nums[minIndex]=_candidates[p].numberOfVotes;
	               
	               //重新记下最小得票者 Recount the smallest ticket winner
	               min=_nums[0];
	               minIndex=0;
	               for(uint j=0;j<_addrs.length;j++){
	                   if(_nums[j]<min){
		                     min=_nums[j];
		                     minIndex=j;
		               }
	               }
	               min=_nums[minIndex];
               }
             }
        }
        //记录下被选中的候选人
        for(uint n=0;n<_addrs.length;n++){
           candidateIndexArray.push(voteStages[round].candidateIndexMap[_addrs[n]]);
        }
        return (_addrs,_facilitys,_nums);
    }
    /**
     * 获取指定阶段投票人的快照余额和总投票数
     * Get the snapshot balances and total votes of voters.
      */
    function fechVoteMainInfoBySnapshotBlock(
        uint _snapshotBlock
    ) onlyVoteAfterOpen public constant returns (
        uint snapshotBalance,
        uint voteNumber
    ){
        return fechVoteMainInfoForVoterBySnapshotBlock(msg.sender,_snapshotBlock);
    }
    
    function fechVoteMainInfoForVoterBySnapshotBlock(
        address voterAddr,
        uint _snapshotBlock
    ) onlyVoteAfterOpen public constant returns (
        uint snapshotBalance,
        uint voteNumber
    ){
        uint voteStageIndex=voteStageIndexMap[_snapshotBlock];
        if(voteStageIndex==0){
            require(_snapshotBlock==voteStages[0].snapshotBlock);
        }
        uint index = voteStages[voteStageIndex].voterIndexMap[voterAddr];
        if(index==0){//没投过票 No vote
        	return (0,0);
        }
        return (
            voteStages[voteStageIndex].voterArray[index].snapshotBalance,
            voteStages[voteStageIndex].voterArray[index].voteNumber
        );
    }
    /**
     * 获取当前阶段投票人的快照余额和总投票数
     * Get the snapshot balances and total votes of voters.
      */
    function fechVoteMainInfo(
    ) onlyVoteAfterOpen public constant returns (
        uint snapshotBalance,
        uint voteNumber
    ){
        return fechVoteMainInfoBySnapshotBlock(currentSnapshotBlock);
    }
    function fechVoteMainInfoForVoter(
        address voterAddr
    ) onlyVoteAfterOpen public constant returns (
        uint snapshotBalance,
        uint voteNumber
    ){
        return fechVoteMainInfoForVoterBySnapshotBlock(voterAddr,currentSnapshotBlock);
    }
    
    /**
     * 获取指定阶段投票人的所有投票情况 Get all the votes of voters.
     */
    function fechVoteInfoForVoterBySnapshotBlock(
        address voterAddr,
        uint _snapshotBlock
    ) onlyVoteAfterOpen public constant returns (
        address[] addrs,
        uint[] nums
    ){
        uint voteStageIndex=voteStageIndexMap[_snapshotBlock];
        if(voteStageIndex==0){
            require(_snapshotBlock==voteStages[0].snapshotBlock);
        }
        uint index = voteStages[voteStageIndex].voterIndexMap[voterAddr];
        if(index==0){//没投过票 No vote
        	return (new address[](0),new uint[](0));
        }
        
        uint vvcl=voteStages[voteStageIndex].voterArray[index].candidateMapAddrs.length-1;
        address[] memory _addrs=new address[](vvcl);
        uint[] memory _nums=new uint[](vvcl);
        for(uint i = 1;i<=vvcl;i++){
            _nums[i-1]=voteStages[voteStageIndex].voterArray[index].candidateMap[
                voteStages[voteStageIndex].voterArray[index].candidateMapAddrs[i]
            ];
            _addrs[i-1]=voteStages[voteStageIndex].voterArray[index].candidateMapAddrs[i];
        }
        return (_addrs,_nums);
    }
    /**
     * 获取当前阶段投票人的所有投票情况 Get all the votes of voters.
     */
    function fechVoteInfoForVoter(
        address voterAddr
    ) onlyVoteAfterOpen public constant returns (
        address[] addrs,
        uint[] nums
    ){
        return fechVoteInfoForVoterBySnapshotBlock(voterAddr,currentSnapshotBlock);
    }
    /**
     * 根据阶段序号得到阶段blockNum(取得快照的区块号)
     */
    function fechSnapshotBlockByIndex(
        uint _index
    ) onlyVoteAfterOpen public constant returns (
        uint _snapshotBlock
    ){
        return voteStages[_index].snapshotBlock;
    }
    /**
     * 根据blockNum(取得快照的区块号)得到阶段序号
     */
    function fechStageIndexBySnapshotBlock(
        uint _snapshotBlock
    ) onlyVoteAfterOpen public constant returns (
        uint _index
    ){
        return voteStageIndexMap[_snapshotBlock];
    }
    /**
     * 得到当前阶段序号（轮次）
     */
    function fechCurrentSnapshotBlockIndex(
    ) onlyVoteAfterOpen public constant returns (
        uint _index
    ){
        return voteStageIndexMap[currentSnapshotBlock];
    }
    /**
     * 获取指定阶段候选人的总得票数，根据指定的投票轮次
     * Total number of votes obtained from candidates
     */
    function fechVoteNumForCandidateBySnapshotBlock(
        address candidateAddr,
        uint _snapshotBlock
    ) onlyVoteAfterOpen public constant returns (
        uint num
    ){
        uint voteStageIndex=voteStageIndexMap[_snapshotBlock];
        if(voteStageIndex==0){
            require(_snapshotBlock==voteStages[0].snapshotBlock);
        }
        uint index = voteStages[voteStageIndex].candidateIndexMap[candidateAddr];
        require(index>0);
        return voteStages[voteStageIndex].candidateArray[index].numberOfVotes;
    }
    /**
     * 获取当前阶段候选人的累计总得票数，根据指定的投票轮次
     * Total number of votes obtained from candidates
     */
    function fechVoteNumForCandidate(
        address candidateAddr
    ) onlyVoteAfterOpen public constant returns (
        uint num
    ){
        return fechVoteNumForCandidateBySnapshotBlock(candidateAddr,currentSnapshotBlock);
    }
    /**
     * 获取候选人指定阶段的投票详细情况
     */
    function fechVoteResultForCandidateBySnapshotBlock(
       address candidateAddr,
       uint _snapshotBlock
    ) onlyVoteAfterOpen public constant returns (
        address[] addrs,
        uint[] nums
    ){
        uint voteStageIndex=voteStageIndexMap[_snapshotBlock];
        if(voteStageIndex==0){
            require(_snapshotBlock==voteStages[0].snapshotBlock);
        }
        uint index = voteStages[voteStageIndex].candidateIndexMap[candidateAddr];
        require(index>0);
        // 如果候选人存在,即时更新竞选情况 If candidates exist, update the campaign immediately.
        uint vcvl=voteStages[voteStageIndex].candidateArray[index].voterMapAddrs.length-1;
        address[] memory _addrs=new address[](vcvl);
        uint[] memory _nums=new uint[](vcvl);
        for(uint i=1;i<=vcvl;i++){
            _nums[i-1]=voteStages[voteStageIndex].candidateArray[index].voterMap[
                voteStages[voteStageIndex].candidateArray[index].voterMapAddrs[i]
            ];
            _addrs[i-1]=voteStages[voteStageIndex].candidateArray[index].voterMapAddrs[i];
        }
        return (_addrs,_nums);
    }
    /**
     * 获取当前阶段候选人的投票详细情况 
     */
    function fechVoteResultForCandidate(
       address candidateAddr
    ) onlyVoteAfterOpen public constant returns (
        address[] addr,
        uint[] nums
    ){
        return fechVoteResultForCandidateBySnapshotBlock(candidateAddr,currentSnapshotBlock);
    }
    /**
     * 获取指定阶段候选人所有得票情况
     */
    function fechAllVoteResultBySnapshotBlock(
        uint _snapshotBlock
    ) onlyVoteAfterOpen public constant returns (
        address[] addrs,
        uint[] nums
    ){
        uint voteStageIndex=voteStageIndexMap[_snapshotBlock];
        if(voteStageIndex==0){
            require(_snapshotBlock==voteStages[0].snapshotBlock);
        }
        require(voteStages[voteStageIndex].candidateArray.length>1);
        uint vcl=voteStages[voteStageIndex].candidateArray.length-1;
        address[] memory _addrs=new address[](vcl);
        uint[] memory _nums=new uint[](vcl);
        for (uint i = 1;i<=vcl;i++){
            _addrs[i-1]=voteStages[voteStageIndex].candidateArray[i].candidateAddr;
            _nums[i-1]=voteStages[voteStageIndex].candidateArray[i].numberOfVotes;
        }
        return (_addrs,_nums);
    }
    /**
     * 获取指定阶段的前一个阶段（轮次）候选人所有得票情况
     * 如果更新了地址，返回的是更新的地址数据
     */
    function fechAllVoteResultPreStageByBlock(
        uint _block
    ) onlyVoteAfterOpen public constant returns (
       uint fromBlock,
       uint toBlock,
       address[] addrs,
       uint[] nums
    ){
        uint voteStageIndex=voteStageIndexMap[currentSnapshotBlock];
        if(voteStageIndex<=round){
            return (0,0,new address[](0),new uint[](0));
        }
        if(_block>=voteStages[voteStageIndex].createSnapshotBlock){
            if(voteStageIndex<2){
                return (0,0,new address[](0),new uint[](0));
            }else if(voteStages[voteStageIndex-1].candidateArray.length<2){
                return (0,0,new address[](0),new uint[](0));
            }else{
		        uint vcl=voteStages[voteStageIndex-1].candidateArray.length-1;
		        address[] memory _addrs=new address[](vcl);
		        uint[] memory _nums=new uint[](vcl);
		        for (uint i = 1;i<=vcl;i++){
		            _addrs[i-1]=voteStages[voteStageIndex-1].candidateArray[i].candidateAddr;
		            
		            _nums[i-1]=voteStages[voteStageIndex-1].candidateArray[i].numberOfVotes;
		        }
		        return (
		            voteStages[voteStageIndex-1].createSnapshotBlock,
		            voteStages[voteStageIndex].createSnapshotBlock,
		            _addrs,
		            _nums
		        );
            }
        }else{
            return (0,0,new address[](0),new uint[](0));
        }
    }
    /**
     * 获取当前阶段候选人所有得票情况
     */
    function fechAllVoteResultForCurrent(
    ) onlyVoteAfterOpen public constant returns (
        address[] addrs,
        uint[] nums
    ){
        return fechAllVoteResultBySnapshotBlock(currentSnapshotBlock);
    }
    function fechBalanceByAddress(
        address[] paddrs
    ) onlyVoteAfterOpen public constant returns (
        address[] addrs,
        uint[] nums
    ){
        require(paddrs.length>0);
		uint[] memory _nums=new uint[](paddrs.length);
		for (uint i=0;i<=paddrs.length;i++){
		    address addr=paddrs[i];
		    //防止投票短地址攻击
	        require(addr!=0);
	        uint addrSize;
			assembly {addrSize := extcodesize(addr)}
			require(addrSize==0);
		    _nums[i]=addr.balance;
		}
		address[] memory _addrs=paddrs;
		return (_addrs,_nums);
    }
}