pragma solidity ^0.4.25;

contract HpbBallot {
    uint256 constant public MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256 z){
        if (x>MAX_UINT256-y) {
            revert();
        }
        return x+y;
    }
    function safeSub(uint256 x, uint256 y) internal pure returns (uint256 z){
        if (x<y){
            revert();
        }
        return x-y;
    }
    function safeMul(uint256 x, uint256 y) internal pure returns (uint256 z){
        if (y== 0){
            return 0;
        }
        if (x>MAX_UINT256 / y) {
            revert();
        }
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
    // 选择总共几轮的数据作为选举结果，默认值为6，就是7轮数据的累计得票数为选举结果
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
        // 对候选者投票的投票者数组，用于遍历用途
        // An array of voters for the candidates to be used for traversal.
        address[] voterMapAddrs;
        // 已经投票了投票人账户地址-》投票数
        mapping (address => uint) voterMap;
        //投票者数组下标，用于快速定位投票者信息，投票人账户地址-》投票者数组下标
        mapping (address => uint) voterMapAddrsIndex;
    }
    // 投票结构体
    // Voting structure
    struct Voter{
        // 投票人的账户地址
        // Address of voters
        address voterAddr;
        // 快照余额
        // Snapshot balance
        uint snapshotBalance;
        // 投票人已经投票数(实际投票数)
        // Voters have voted number.
        uint voteNumber;
        // 用于遍历投票了的候选者用途
        // Candidate use for traversing voting
        address[] candidateMapAddrs;
        // 已经投票了的候选者账户地址-》投票数
        // The candidate&#39;s account address has been voted
        mapping (address => uint) candidateMap;
    }
    /**
     * 轮次投票结构体
     * 为了便于持续性投票，一般会每天随机选取一个已存在的区块号作为快照重新设置投票余额,
     * 这样就会重新计算实际生效的投票数额，让用户可以持续性参与投票
     */
    struct VoteRound{
        
        //每变换一次投票余额对应的区块快照号(切换投票轮次)
        uint snapshotBlock;
        //设置切换轮次操作所对应的区块号
        uint createSnapshotBlock;
        //候选者的数组
        //An array of candidates
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
        // 投票者数组
        // An array of voters
        Voter[] voterArray;
        // 投票者的地址与投票者序号（voterArray下标）对应关系，便于查询和减少gas消耗
        // The voter&#39;s address corresponds to the voter&#39;s ordinal number (voter Array subscript),
        // making it easy to query and reduce gas consumption
        mapping (address => uint) voterIndexMap;
    }
    //初始化投票结构体，每变换一次投票余额对应的区块快照号(切换投票次)，就要对投票信息进行初始化操作，
    //对前一个轮次的投票数据依据新投票余额快照号重新计算，然后初始化到当前轮次,便于持续性投票功能
    struct InitVote{
        // 是否已经对上一轮的数据重新计算，然后初始化到当前轮次（用于投票的持续性）
        bool hasInitVote;
        //设置下一轮投票余额快照号
        uint nextSnapshotBlock;
        //缓存投票者下一个轮次投票余额,投票者地址-》投票者快照投票余额
        mapping (address => uint) nextVoterBalance;
    }
    //分轮次投票
    VoteRound[] public voteRounds;
    //轮次快照号对应的轮次号(VoteRound的下标)
    mapping (uint => uint) voteRoundIndexMap;
    //当前轮次快照号
    uint public currentSnapshotBlock;
    //初始化投票信息
    InitVote initVote;
	//候选者名称序列(该版本周期内[3个月]的所有关联候选者名称）
    mapping (address => string) public candidateNameMap;
    //候选者机器相关信息(该版本周期内[3个月])，比如cid+","+hid
    mapping (address => string) public candidateFacilityMap;
    //用于候选者修改地址的情况，仅仅用于获取最终数据的时候使用
    mapping (address => address) public candidateNewAddressMap;
    
    //最终选举出的候选人下标，便于查询
    uint[] public candidateIndexArray;
    // 最终获选者总数（容量，获选者数量上限）
    // the total number of final winners (capacity, the upper limit of the number of candidates selected)
    uint public capacity;
	//未了持续性投票，每次切换新一轮快照余额的时候会对前一轮投票的数据复制到当前轮次中来，保证持续性的投票
    modifier onlyInitVoteAfter{
        require(initVote.hasInitVote == true);
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
    // 票和撤销投票日志，flag：0撤销，1投票
    // vote
    event DoVoted(uint indexed index ,address indexed voteAddr,address indexed candidateAddr,uint num,uint flag);
    // 改变投票区间值,改变保证金最少金额,改变投票版本号
    // Change the voting interval and change the voting number.
    event CreateContract(uint indexed version,uint openBlock, uint closeBlock,uint capacity);
    // 更新轮次轮次
    event ChangeRoundBlock(uint indexed preRoundBlock,uint indexed stageBlock);
    // 设置快照余额
    event SetSnapshotBalance(uint indexed voteRoundIndex,address indexed voterAddr,uint _snapshotBalance);
    //对上一轮的自动持续性投票用途
    event VoteNoLockByAdminInvokeDoVoted(address voterAddr,address candidateAddr,uint num);
    // 记录发送HPB的发送者地址和发送的金额
    // Record the sender address and the amount sent to send HPB.
    event ReceivedHpb(address indexed sender, uint amount);
    // 接受HPB转账，比如投票应用赞助(用于自动投票支出)
    // Accept HPB transfer
    function () payable  external{
        emit ReceivedHpb(msg.sender, msg.value);
    }
    // HPB首席管理员(合约拥有者，可以基金会掌握)
    address public owner;
    /**
     * 只有HPB首席管理员可以调用
     * Only the HPB foundation account (administrator) can call.
     */
    modifier onlyOwner{
        require(msg.sender == owner);
        // Do not forfetch the "_;"! It will be replaced by the actual function
        // body when the modifier is used.
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public{
        owner = newOwner;
    }
    /**
     * 开启合约，并设置当前区块号为开启区块号
     */
    function toOpenVote() onlyOwner public{
        openBlock = block.number;
    }
    /**
     * 关闭合约,并设置当前区块号为关闭区块号
     */
    function toCloseVote() onlyOwner public{
        closeBlock = block.number;
    }
    function setOpenBlock(uint _openBlock) onlyOwner public{
        require(_openBlock< closeBlock);
        openBlock = _openBlock;
    }
    function setCloseBlock(uint _closeBlock) onlyOwner public{
        require(openBlock< _closeBlock);
        closeBlock = _closeBlock;
    }
    function setCapacity(uint _capacity) onlyOwner public{
        capacity = _capacity;
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
    // 管理员，用于切换轮次和设置快照余额
    // Administrators who set up snapshot balances for voters
    mapping (address => address) public adminMap;
    // 必须是管理员才能切换轮次和设置快照余额
    modifier onlyAdmin{
        require(adminMap[msg.sender] != 0);
        _;
    }
    // 增加普通管理员（管理合约，比如设置快照余额权利）
    function addAdmin(address addr) onlyOwner public{
        require(adminMap[addr]== 0);
        adminMap[addr] = addr;
    }
    // 删除普通管理员
    function deleteAdmin(address addr) onlyOwner public{
        require(adminMap[addr] != 0);
        adminMap[addr]=0;
    }
    // 设置选举结果的截止轮数（经过几轮投票就可出选举结果）
    function setRound(uint _round) onlyOwner public{
        uint _voteRoundIndex = voteRoundIndexMap[currentSnapshotBlock];
        require(_round>_voteRoundIndex);
        round=_round;
    }
    /**
     * Constructor function
     * 构造函数 初始化投票智能合约的部分依赖参数
     */
    constructor(// 开启合约的区块号
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
    )payable public{
        require(_openBlock<_closeBlock);
        owner = msg.sender;
        openBlock= _openBlock;
        closeBlock= _closeBlock;
        capacity=_capacity;
        version=_version;
        // 设置默认普通管理员（合约创建者）
        adminMap[owner]=owner;
        // 设置首轮次区块快照号为合约开启区块号
        currentSnapshotBlock=_openBlock;
        voteRounds.length++;
        voteRoundIndexMap[currentSnapshotBlock]=0;
        voteRounds[0].snapshotBlock=currentSnapshotBlock;
        voteRounds[0].createSnapshotBlock=block.number;
        voteRounds[0].voterIndexMap[msg.sender]=0;
        // 设置第一个位置（为了定位不出错，第一个位置不占用）
        voteRounds[0].voterArray.push(
            Voter(msg.sender,0,0,new address[](0))
        );
        voteRounds[0].candidateIndexMap[msg.sender]=0;
        // 设置第一位置（为了定位不出错，第一个位置不占用）
        voteRounds[0].candidateArray.push(
            Candidate(msg.sender,0,new address[](0))
        );
        initVote.hasInitVote=true;
        initVote.nextSnapshotBlock=0;
        emit CreateContract(_version,_openBlock,_closeBlock,_capacity);
    }
  
    /**
     * 增加候选者 ,必须首轮才可以添加候选人 add Candidate 
     * @param _candidateAddr 候选者名称账户地址
     * @param _facility 候选者机器相关信息,比如cid+","+hid
     * @param _name 候选者名称 
     */
    function addCandidate(
        address _candidateAddr,
        string _facility,
        string _name
    ) onlyAdmin onlyVoteAfterOpen public{
        //必须首轮才可以添加候选人
        require(voteRoundIndexMap[currentSnapshotBlock]==0);
        uint index = voteRounds[0].candidateIndexMap[_candidateAddr];
        //必须候选人地址还未添加
        require(index == 0);
        index = voteRounds[0].candidateArray.length;
        voteRounds[0].candidateIndexMap[_candidateAddr]=index;
        voteRounds[0].candidateArray.push(Candidate(_candidateAddr,0,new address[](0)));
        voteRounds[0].candidateArray[index].voterMapAddrs.push(msg.sender);
        candidateNameMap[_candidateAddr]=_name;
        candidateFacilityMap[_candidateAddr]=_facility;
        emit CandidateAdded(_candidateAddr,_facility,_name);
    }
    function addCandidateBatch(
        address[] _candidateAddrs
    ) onlyAdmin onlyVoteAfterOpen public{
        for(uint i = 0;i<_candidateAddrs.length;i++){
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
     * 删除候选者 Delete Candidate 
     * @param _candidateAddr 候选者账户地址 Candidate account address
     */
    function deleteCandidates(
        address _candidateAddr
    ) onlyOwner onlyVoteAfterOpen public{
        uint voteRoundIndex = voteRoundIndexMap[currentSnapshotBlock];
        uint index = voteRounds[voteRoundIndex].candidateIndexMap[_candidateAddr];
        //候选者必须存在
        require(index!= 0);
        // 删除该候选者对应的投票者关联的候选者信息
        for(uint n = 1;n<voteRounds[voteRoundIndex].candidateArray[index].voterMapAddrs.length;n++){
            // 得到投票者 fetch voter
            uint voterIndex = voteRounds[voteRoundIndex].voterIndexMap[
                voteRounds[voteRoundIndex].candidateArray[index].voterMapAddrs[n]
            ];
            uint cindex = 0;
            // 遍历对应投票者里面的候选者信息，并删除其中对应的该候选者
            for(uint k = 1;k<voteRounds[voteRoundIndex].voterArray[voterIndex].candidateMapAddrs.length-1;k++){
                if(cindex==0&&voteRounds[voteRoundIndex].voterArray[voterIndex].candidateMapAddrs[k]==_candidateAddr){
                    // 得到候选者所处投票者结构体中的位置
                    // fetchs the position of the candidate in the structure of the voters.
                    cindex=k;
                }
                // 如果投票者结构体中候选者存在 If the candidate in the voter structure is exist
                if(cindex>0&&k>=cindex){
                    voteRounds[voteRoundIndex].voterArray[voterIndex].candidateMapAddrs[k]=
	                voteRounds[voteRoundIndex].voterArray[voterIndex].candidateMapAddrs[k+1];
                }
            }
            // 撤回已经投的票
            uint hasVoteNum=voteRounds[voteRoundIndex].voterArray[voterIndex].candidateMap[_candidateAddr];
            if(hasVoteNum>0){
	            voteRounds[voteRoundIndex].voterArray[voterIndex].voteNumber=safeSub(
	                voteRounds[voteRoundIndex].voterArray[voterIndex].voteNumber,
		            hasVoteNum
		        );
            }
            voteRounds[voteRoundIndex].voterArray[voterIndex].candidateMap[_candidateAddr]=0;
            delete voteRounds[voteRoundIndex].voterArray[voterIndex].candidateMapAddrs[
                voteRounds[voteRoundIndex].voterArray[voterIndex].candidateMapAddrs.length-1
            ];
            voteRounds[voteRoundIndex].voterArray[voterIndex].candidateMapAddrs.length--;
        }
        for (uint i = index;i<voteRounds[voteRoundIndex].candidateArray.length-1;i++){
            voteRounds[voteRoundIndex].candidateArray[i] = voteRounds[voteRoundIndex].candidateArray[i+1];
        }
        delete voteRounds[voteRoundIndex].candidateArray[
            voteRounds[voteRoundIndex].candidateArray.length-1
        ];
        voteRounds[voteRoundIndex].candidateArray.length--;
        voteRounds[voteRoundIndex].candidateIndexMap[_candidateAddr]=0;
        emit CandidateDeleted(_candidateAddr);
    
    }
    function deleteCandidatesBatch(
        address[] _candidateAddrs
    ) onlyOwner onlyVoteAfterOpen public{
        for(uint i = 0;i<_candidateAddrs.length;i++){
            deleteCandidates(_candidateAddrs[i]);
        }
    }
    
    function setNextSnapshotBlock(
        uint nextSnapshotBlock
    ) onlyAdmin onlyVoteAfterOpen onlyInitVoteAfter public{
        initVote.nextSnapshotBlock=nextSnapshotBlock;
        uint voteRoundIndex = voteRoundIndexMap[currentSnapshotBlock];
        require(voteRounds[voteRoundIndex].voterArray.length>1);
        uint cl = voteRounds[voteRoundIndex].voterArray.length;
        for(uint i = 1;i<cl;i++){
           if(voteRounds[voteRoundIndex].voterArray[i].voteNumber>0){
	           initVote.nextVoterBalance[
	               voteRounds[voteRoundIndex].voterArray[i].voterAddr
	           ]=voteRounds[voteRoundIndex].voterArray[i].voterAddr.balance;
           }
        }
    }
    
    function fetchNextSnapshotBlock(
    ) onlyAdmin onlyVoteAfterOpen public constant returns (
        uint nextSnapshotBlock
    ){
        return initVote.nextSnapshotBlock;
    }
    /**
     * 更新轮次轮次
     */
    function changeRoundBlock(
    ) onlyVoteAfterOpen onlyAdmin public{
        require(initVote.nextSnapshotBlock!=0);
        uint _snapshotBlock = initVote.nextSnapshotBlock;
        require(currentSnapshotBlock<_snapshotBlock);
        // 获取当前轮次的位置（序号）
        uint _voteRoundIndex =voteRoundIndexMap[currentSnapshotBlock];
        voteRounds.length++;
        currentSnapshotBlock=_snapshotBlock;
        voteRoundIndexMap[_snapshotBlock]=_voteRoundIndex+1;
        voteRounds[_voteRoundIndex].snapshotBlock=_snapshotBlock;
        voteRounds[_voteRoundIndex].createSnapshotBlock=block.number;
        voteRounds[_voteRoundIndex].voterIndexMap[msg.sender]=0;
        // 设置第一位置
        // Set the first position.
        voteRounds[_voteRoundIndex].voterArray.push(
            Voter(msg.sender,0,0,new address[](0))
        );
        // 复制选出的候选者
        if(_voteRoundIndex>round){
            voteResult();
            // 奖励轮次轮次
            require(candidateIndexArray.length>0);
            // 设置第一位置
            // Set the first position.
            voteRounds[_voteRoundIndex].candidateArray.push(
                Candidate(msg.sender,0,new address[](0))
            );
            voteRounds[_voteRoundIndex].candidateIndexMap[msg.sender]=0;
            for(uint m = 0;m<candidateIndexArray.length;m++){
                voteRounds[_voteRoundIndex].candidateArray.push(
                    Candidate(
                        voteRounds[0].candidateArray[
                            candidateIndexArray[m]
                        ].candidateAddr,
	        	        0,
	        	        new address[](0)
	        	    )
	        	);
                voteRounds[_voteRoundIndex].candidateIndexMap[
                    voteRounds[0].candidateArray[
                        candidateIndexArray[m]
                    ].candidateAddr
                ]=safeAdd(m,1);
                voteRounds[_voteRoundIndex].candidateArray[
                    safeAdd(m,1)
                ].voterMapAddrs.push(msg.sender);
            }
        } else {
            // 竞选轮次轮次
            for(uint k = 0;k<voteRounds[0].candidateArray.length;k++){
                voteRounds[_voteRoundIndex].candidateArray.push(
                    Candidate(
                        voteRounds[0].candidateArray[k].candidateAddr,
	        	         0,
	        	         new address[](0)
	        	    )
	        	);
                voteRounds[_voteRoundIndex].candidateIndexMap[
                    voteRounds[0].candidateArray[k].candidateAddr
                ]=k;
                voteRounds[_voteRoundIndex].candidateArray[k].voterMapAddrs.push(msg.sender);
            }
        }
        initVote.hasInitVote=false;
        voteNoLockByAdmin();
        initVote.hasInitVote=true;
        initVote.nextSnapshotBlock=0;
        emit ChangeRoundBlock(voteRounds[_voteRoundIndex-1].snapshotBlock,_snapshotBlock);
    }
  
    /**
     * 撤回当前轮次对某个候选人的投票 
     */
    function cancelVoteForCandidate(
        address candidateAddr,
    	uint num
    ) onlyVoteAfterOpen public{
        address voterAddr = msg.sender;
        uint voteRoundIndex = voteRoundIndexMap[currentSnapshotBlock];
        uint index = voteRounds[voteRoundIndex].voterIndexMap[voterAddr];
        // 必须投过票
        require(index!=0);
        uint candidateIndex = voteRounds[voteRoundIndex].candidateIndexMap[candidateAddr];
        // 候选人必须存在 Candidates must exist
        require(candidateIndex!=0);
        // 必须已投候选者票数不少于取消数量
        uint cnum = voteRounds[voteRoundIndex].voterArray[index].candidateMap[candidateAddr];
        require(cnum>=num);
        // 处理候选者中的投票信息
        voteRounds[voteRoundIndex].candidateArray[candidateIndex].voterMap[voterAddr]=safeSub(cnum,num);
        voteRounds[voteRoundIndex].candidateArray[candidateIndex].numberOfVotes=safeSub(
            voteRounds[voteRoundIndex].candidateArray[candidateIndex].numberOfVotes,num
        );
        // 处理投票者里面的投票信息
        voteRounds[voteRoundIndex].voterArray[index].candidateMap[candidateAddr]=safeSub(cnum,num);
        voteRounds[voteRoundIndex].voterArray[index].voteNumber=safeSub(
            voteRounds[voteRoundIndex].voterArray[index].voteNumber,num
        );
        emit DoVoted(voteRoundIndex,voterAddr,candidateAddr,num,0);
    }
    /**
     * 设置投票人的快照余额（以指定的区块号为准，到时候由官方或者HPB基金会对外公布）
     * Set the voter&#39;s snapshot balance (subject to the designated block number, 
     * to be published by the official or HPB Foundation)
     */
    function  setSnapshotBalance(
        address voterAddr,
    	uint _snapshotBalance
    )onlyAdmin onlyVoteAfterOpen public{
        require(_snapshotBalance>0);
        uint voteRoundIndex = voteRoundIndexMap[currentSnapshotBlock];
        uint index = voteRounds[voteRoundIndex].voterIndexMap[voterAddr];
        if (index == 0) { // 如果从没投过票，就添加投票人 If you never cast a vote, you add voters.
            index =voteRounds[voteRoundIndex].voterArray.length;
            voteRounds[voteRoundIndex].voterIndexMap[voterAddr] =index;
            voteRounds[voteRoundIndex].voterArray.push(
                Voter(voterAddr,_snapshotBalance,0,new address[](0))
            );
            voteRounds[voteRoundIndex].voterArray[index].candidateMapAddrs.push(msg.sender);
        } else {
            voteRounds[voteRoundIndex].voterArray[index].snapshotBalance=_snapshotBalance;
        }
        emit SetSnapshotBalance(voteRoundIndex,voterAddr,_snapshotBalance);
    }
   
    function  setNextSnapshotBalance(
        address voterAddr,
    	uint _snapshotBalance
    )onlyAdmin onlyVoteAfterOpen public{
        require(_snapshotBalance>0);
        require(initVote.nextSnapshotBlock!=0);
        initVote.nextVoterBalance[voterAddr]=_snapshotBalance;
    }
    
    function  getNextSnapshotBalance(
        address voterAddr
    )onlyAdmin onlyVoteAfterOpen public constant returns (
        uint _snapshotBalance
    ){
        return initVote.nextVoterBalance[voterAddr];
    }
    function  getNextSnapshotBalanceOfMul(
        address[] voterAddrs
    )onlyAdmin onlyVoteAfterOpen public constant returns (
        uint[] _snapshotBalances
    ){
        uint cl=voterAddrs.length;
        uint[] memory snapshotBalances = new uint[](cl);
        for(uint i=0;i<cl;i++){
            snapshotBalances[i]=initVote.nextVoterBalance[voterAddrs[i]];
        }
        return snapshotBalances;
    }
    function  setCurrentAndNextSnapshotBalance(
        address voterAddr,
    	uint _csnapshotBalance,
    	uint _nsnapshotBalance
    )onlyAdmin onlyVoteAfterOpen public{
        setSnapshotBalance(voterAddr,_csnapshotBalance);
        setNextSnapshotBalance(voterAddr,_nsnapshotBalance);
    }
    
    function voteNoLockBatchByAdmin(
        address[] voterAddrs,
        address[] candidateAddrs,
    	uint[] _nums
    )onlyAdmin onlyInitVoteAfter onlyVoteAfterOpen public{
        uint voteRoundIndex = voteRoundIndexMap[currentSnapshotBlock];
        uint cl=voterAddrs.length;
        for(uint i=0;i<cl;i++){
	       uint index = voteRounds[voteRoundIndex].voterIndexMap[voterAddrs[i]];
	       // 必须设置过快照
	       require(index != 0);
	       // 剩余的可投票数必须不少于投票数
	       require(safeSub(
	           voteRounds[voteRoundIndex].voterArray[index].snapshotBalance,
	           voteRounds[voteRoundIndex].voterArray[index].voteNumber
	       )>=_nums[i]);
	       doVote(candidateAddrs[i],index,_nums[i]);
        }
    }

    /**
     * 用于自动投票，根据前一个轮次的投票记录程序自动投票
     */
    function  voteNoLockByAdmin(
    )onlyAdmin onlyVoteAfterOpen internal{
        uint voteRoundIndex = voteRoundIndexMap[currentSnapshotBlock];
        require(voteRoundIndex!=0);
        //
        uint preRoundIndex = voteRoundIndex-1;
        require(voteRounds[preRoundIndex].voterArray.length>1);
        uint cl = voteRounds[preRoundIndex].voterArray.length;
        for(uint i = 1;i<cl;i++){
            uint bl = initVote.nextVoterBalance[
                voteRounds[preRoundIndex].voterArray[i].voterAddr
            ];
            uint voteNumber = voteRounds[preRoundIndex].voterArray[i].voteNumber;
            if(bl>0&&voteNumber>0){
                //设置权重(比例)
                uint proportion = 100000;
                if(voteNumber>bl){
                    proportion=safeMul(bl,proportion)/voteNumber;
                }
                //设置快照余额
                setSnapshotBalance(voteRounds[preRoundIndex].voterArray[i].voterAddr,bl);
                uint vvcl = voteRounds[preRoundIndex].voterArray[i].candidateMapAddrs.length;
                //遍历候选者
                for(uint k = 1;k<vvcl;i++){
                    address _candidateAddr = voteRounds[preRoundIndex].voterArray[i].candidateMapAddrs[k];
                    uint _candidateIndex = voteRounds[voteRoundIndex].candidateIndexMap[_candidateAddr];
			        // 候选人必须存在
			        if(_candidateIndex!=0){
	                    uint _num = voteRounds[preRoundIndex].voterArray[i].candidateMap[_candidateAddr];
	                    uint num = safeMul(_num,proportion)/100000;
	                    if(num>10000000000){
	                        emit VoteNoLockByAdminInvokeDoVoted(
	                            voteRounds[preRoundIndex].voterArray[i].voterAddr,
	                        	_candidateAddr,
	                        	num
	                        );
	                        doVote(_candidateAddr,voteRoundIndex,num);
	                    }
			        }
                }
            }
        }
    }

    /**
     * 用于非质押(锁定)投票  For non locked voting
     */
    function  voteNoLock(
        address candidateAddr,
    	uint num
    ) onlyVoteAfterOpen onlyInitVoteAfter public{
        // 获取投票人的账户地址 fetch the address of the voters.
        address voterAddr = msg.sender;
        // 防止投票短地址攻击
        require(voterAddr!=0);
        require(candidateAddr!=0);
        uint voterAddrSize;
        assembly {voterAddrSize := extcodesize(voterAddr)}
        require(voterAddrSize==0);
        uint candidateAddrSize;
        assembly {candidateAddrSize := extcodesize(candidateAddr)}
        require(candidateAddrSize==0);
        uint voteRoundIndex = voteRoundIndexMap[currentSnapshotBlock];
        uint index = voteRounds[voteRoundIndex].voterIndexMap[voterAddr];
        // 必须设置过快照
        require(index != 0);
        // 剩余的可投票数必须不少于投票数
        require(safeSub(
            voteRounds[voteRoundIndex].voterArray[index].snapshotBalance,
            voteRounds[voteRoundIndex].voterArray[index].voteNumber
        )>=num);
        doVote(candidateAddr,index,num);
    }
    /**
     * 用于批量非质押(锁定)投票  For non locked voting
     */
    function  voteNoLockBatch(
        address[] candidateAddrs,
    	uint[] nums
    ) onlyVoteAfterOpen public{
        for(uint i = 0;i<candidateAddrs.length;i++){
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
    ) onlyVoteAfterOpen internal{
        require(num>0);
        uint voteRoundIndex = voteRoundIndexMap[currentSnapshotBlock];
        uint candidateIndex = voteRounds[voteRoundIndex].candidateIndexMap[candidateAddr];
        // 候选人必须存在 Candidates must exist
        require(candidateIndex!=0);
        if(voteRounds[voteRoundIndex].candidateArray[candidateIndex].voterMapAddrsIndex[
            voteRounds[voteRoundIndex].voterArray[index].voterAddr
        ]<1){
            voteRounds[voteRoundIndex].candidateArray[candidateIndex].voterMapAddrsIndex[
                voteRounds[voteRoundIndex].voterArray[index].voterAddr
            ]=1;
            voteRounds[voteRoundIndex].candidateArray[candidateIndex].voterMapAddrs.push(
                voteRounds[voteRoundIndex].voterArray[index].voterAddr
            );
            voteRounds[voteRoundIndex].candidateArray[candidateIndex].voterMap[
                voteRounds[voteRoundIndex].voterArray[index].voterAddr
            ]=num;
            voteRounds[voteRoundIndex].voterArray[index].candidateMapAddrs.push(candidateAddr);
            voteRounds[voteRoundIndex].voterArray[index].candidateMap[candidateAddr]=num;
        } else {
            voteRounds[voteRoundIndex].candidateArray[candidateIndex].voterMap[
                voteRounds[voteRoundIndex].voterArray[index].voterAddr
            ]=safeAdd(
                voteRounds[voteRoundIndex].candidateArray[candidateIndex].voterMap[
                    voteRounds[voteRoundIndex].voterArray[index].voterAddr
                ],num
            );
            voteRounds[voteRoundIndex].voterArray[index].candidateMap[candidateAddr]=safeAdd(
                voteRounds[voteRoundIndex].voterArray[index].candidateMap[candidateAddr],num
            );
        }
        // 投票人已投总数累加
        voteRounds[voteRoundIndex].voterArray[index].voteNumber=safeAdd(
            voteRounds[voteRoundIndex].voterArray[index].voteNumber,num
        );
        // 候选者得票数累加
        voteRounds[voteRoundIndex].candidateArray[candidateIndex].numberOfVotes=safeAdd(
            voteRounds[voteRoundIndex].candidateArray[candidateIndex].numberOfVotes,num
        );
        emit DoVoted(voteRoundIndex,voteRounds[voteRoundIndex].voterArray[index].voterAddr,candidateAddr,num,1);
    }
    /**
     * string类型转换成bytes32类型
     */
    function stringToBytes32(
        string memory source
    ) internal pure returns (
        bytes32 result
    ){
        assembly {result := mload(add(source, 32))}
    }
    /**
     * 获取指定轮次所有候选人的详细信息
     * fetch detailed information about all candidates.
     */
    function fetchAllCandidatesBySnapshotBlock(
        uint _snapshotBlock
    ) onlyVoteAfterOpen public constant returns (
        address[] addrs,
        bytes32[] names,
        bytes32[] facilitys
    ){
        uint voteRoundIndex = voteRoundIndexMap[_snapshotBlock];
        if(voteRoundIndex==0){
            require(_snapshotBlock==voteRounds[0].snapshotBlock);
        }
        require(voteRounds[voteRoundIndex].candidateArray.length>1);
        uint cl = voteRounds[voteRoundIndex].candidateArray.length-1;
        address[] memory _addrs = new address[](cl);
        bytes32[] memory _names = new bytes32[](cl);
        bytes32[] memory _facilitys = new bytes32[](cl);
        for(uint i = 1;i<=cl;i++){
            _addrs[i-1]=voteRounds[voteRoundIndex].candidateArray[i].candidateAddr;
            _names[i-1]=stringToBytes32(candidateNameMap[_addrs[i-1]]);
            _facilitys[i-1]=stringToBytes32(candidateFacilityMap[_addrs[i-1]]);
        }
        return (_addrs,_names,_facilitys);
    }
    /**
     * 获取指定轮次所有投票人的详细信息
     * 
     */
    function fetchAllVotersBySnapshotBlock(
        uint _snapshotBlock
    ) onlyVoteAfterOpen public constant returns (
        address[] voterAddrs,
        uint[] snapshotBalances,
        uint[] voteNumbers
    ){
        uint voteRoundIndex = voteRoundIndexMap[_snapshotBlock];
        if(voteRoundIndex==0){
            require(_snapshotBlock==voteRounds[0].snapshotBlock);
        }
        require(voteRounds[voteRoundIndex].voterArray.length>1);
        uint cl = voteRounds[voteRoundIndex].voterArray.length-1;
        address[] memory _addrs = new address[](cl);
        uint[] memory _snapshotBalances = new uint[](cl);
        uint[] memory _voteNumbers = new uint[](cl);
        for(uint i = 1;i<=cl;i++){
            _addrs[i-1]=voteRounds[voteRoundIndex].voterArray[i].voterAddr;
            _snapshotBalances[i-1]=voteRounds[voteRoundIndex].voterArray[i].snapshotBalance;
            _voteNumbers[i-1]=voteRounds[voteRoundIndex].voterArray[i].voteNumber;
        }
        return (_addrs,_snapshotBalances,_voteNumbers);
    }
    /**
     * 得到最终投票选举结果 ,必须在调用voteResult后执行
     * 该方法为常量方法，可以通过消息调用，如果更新了地址，返回的是更新的地址数据
     */
    function fetchVoteResult(
    ) onlyVoteAfterOpen public constant returns(
        address[] addr,
        bytes32[] facilitys,
        uint[] nums
    ){
        uint cl = candidateIndexArray.length;
        address[] memory _addrs = new address[](cl);
        bytes32[] memory _facilitys = new bytes32[](cl);
        uint[] memory _nums = new uint[](cl);
        for(uint m = 0;m<cl;m++){
            _addrs[m]=voteRounds[round].candidateArray[candidateIndexArray[m]].candidateAddr;
            _facilitys[m]=stringToBytes32(candidateFacilityMap[_addrs[m]]);
            _nums[m]=voteRounds[round].candidateArray[candidateIndexArray[m]].numberOfVotes;
        }
        return (_addrs,_facilitys,_nums);
    }
    /**
     * 得到最终投票选举结果 fetch the final vote.
     */
    function voteResult(
    ) onlyVoteAfterOpen public returns(
        address[] addr,
        bytes32[] facilitys,
        uint[] nums
    ){
        uint _voteRoundIndex = voteRoundIndexMap[currentSnapshotBlock];
        // 必须竞选轮次后调用
        require(_voteRoundIndex>round);
        if(candidateIndexArray.length>0){
            return fetchVoteResult();
        } else {
            require(voteRounds[round].candidateArray.length>1);
            uint vcl = voteRounds[round].candidateArray.length-1;
            Candidate[] memory _candidates = new Candidate[](vcl);
            // 取得第round轮的数据作为选举池
            for (uint i = 1;i<=vcl;i++){
                _candidates[i-1]=Candidate(
                    voteRounds[round].candidateArray[i].candidateAddr,
                    voteRounds[round].candidateArray[i].numberOfVotes,
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
        address[] memory _addrs = new address[](capacity);
        bytes32[] memory _facilitys = new bytes32[](capacity);
        uint[] memory _nums = new uint[](capacity);
        uint min = _candidates[0].numberOfVotes;
        uint minIndex = 0;
        for (uint p = 0;p<_candidates.length;p++){
            if(p<capacity){
                // 先初始化获选者数量池 Initialize the number of pools selected first.
                _addrs[p]=_candidates[p].candidateAddr;
                _facilitys[p]=stringToBytes32(candidateFacilityMap[_addrs[p]]);
                _nums[p]=_candidates[p].numberOfVotes;
                // 先记录获选者数量池中得票最少的记录 Record the number of votes selected in the pool.
                if(_nums[p]<min){
                    min=_nums[p];
                    minIndex=p;
                }
            } else {
                if(_candidates[p].numberOfVotes==min){
                    // 对于得票相同的，取持币数量多的为当选
                    /**
                     * if(_candidates[p].candidateAddr.balance>_addrs[minIndex].balance){
                     *     _addrs[minIndex]=_candidates[p].candidateAddr;
                     * 		               _facilitys[minIndex]=stringToBytes32(candidateFacilityMap[_addrs[p]]);
                     * 		               _nums[minIndex]=_candidates[p].numberOfVotes;
                     * }
                     */
                } else if(_candidates[p].numberOfVotes>min){
                    _addrs[minIndex]=_candidates[p].candidateAddr;
                    _facilitys[minIndex]=stringToBytes32(candidateFacilityMap[_addrs[p]]);
                    _nums[minIndex]=_candidates[p].numberOfVotes;
                    // 重新记下最小得票者 Recount the smallest ticket winner
                    min=_nums[0];
                    minIndex=0;
                    for(uint j = 0;j<_addrs.length;j++){
                        if(_nums[j]<min){
                            min=_nums[j];
                            minIndex=j;
                        }
                    }
                    min=_nums[minIndex];
                }
            }
        }
        // 记录下被选中的候选人
        for(uint n = 0;n<_addrs.length;n++){
            candidateIndexArray.push(
                voteRounds[round].candidateIndexMap[_addrs[n]]
            );
        }
        return (_addrs,_facilitys,_nums);
    }
    
    function fetchVoteMainInfoForVoterBySnapshotBlock(
        address voterAddr,
        uint _snapshotBlock
    ) onlyVoteAfterOpen public constant returns (
        uint snapshotBalance,
        uint voteNumber
    ){
        uint voteRoundIndex = voteRoundIndexMap[_snapshotBlock];
        if(voteRoundIndex==0){
            require(_snapshotBlock==voteRounds[0].snapshotBlock);
        }
        uint index = voteRounds[voteRoundIndex].voterIndexMap[voterAddr];
        if(index==0){ // 没投过票 No vote
            return (0,0);
        }
        return (
            voteRounds[voteRoundIndex].voterArray[index].snapshotBalance,
            voteRounds[voteRoundIndex].voterArray[index].voteNumber
        );
    }
    

    /**
     * 获取指定轮次投票人的所有投票情况 fetch all the votes of voters.
     */
    function fetchVoteInfoForVoterBySnapshotBlock(
        address voterAddr,
        uint _snapshotBlock
    ) onlyVoteAfterOpen public constant returns (
        address[] addrs,
        uint[] nums
    ){
        uint voteRoundIndex = voteRoundIndexMap[_snapshotBlock];
        if(voteRoundIndex==0){
            require(_snapshotBlock==voteRounds[0].snapshotBlock);
        }
        uint index = voteRounds[voteRoundIndex].voterIndexMap[voterAddr];
        if(index==0){ // 没投过票 No vote
            return (new address[](0),new uint[](0));
        }
        uint vvcl = voteRounds[voteRoundIndex].voterArray[index].candidateMapAddrs.length-1;
        address[] memory _addrs = new address[](vvcl);
        uint[] memory _nums = new uint[](vvcl);
        for(uint i = 1;i<=vvcl;i++){
            _nums[i-1]=voteRounds[voteRoundIndex].voterArray[index].candidateMap[
                voteRounds[voteRoundIndex].voterArray[index].candidateMapAddrs[i]
            ];
            _addrs[i-1]=voteRounds[voteRoundIndex].voterArray[index].candidateMapAddrs[i];
        }
        return (_addrs,_nums);
    }
    /**
     * 根据轮次序号得到轮次blockNum(取得快照的区块号)
     */
    function fetchSnapshotBlockByIndex(
        uint _index
    ) onlyVoteAfterOpen public constant returns (
        uint _snapshotBlock
    ){
        return voteRounds[_index].snapshotBlock;
    }
    
    /**
     * 根据取得快照的区块号得到轮次序号
     */
    function fetchRoundIndexBySnapshotBlock(
        uint _snapshotBlock
    ) onlyVoteAfterOpen public constant returns (
        uint _index
    ){
        return voteRoundIndexMap[_snapshotBlock];
    }
    /**
     * 得到当前轮次序号（轮次）
     */
    function fetchCurrentSnapshotBlockIndex(
    ) onlyVoteAfterOpen public constant returns (
        uint _index
    ){
        return voteRoundIndexMap[currentSnapshotBlock];
    }
    /**
     * 获取指定轮次候选人的总得票数，根据指定的投票轮次
     * Total number of votes obtained from candidates
     */
    function fetchVoteNumForCandidateBySnapshotBlock(
        address candidateAddr,
        uint _snapshotBlock
    ) onlyVoteAfterOpen public constant returns (
        uint num
    ){
        uint voteRoundIndex = voteRoundIndexMap[_snapshotBlock];
        if(voteRoundIndex==0){
            require(_snapshotBlock==voteRounds[0].snapshotBlock);
        }
        uint index = voteRounds[voteRoundIndex].candidateIndexMap[candidateAddr];
        require(index>0);
        return voteRounds[voteRoundIndex].candidateArray[index].numberOfVotes;
    }
    /**
     * 获取当前轮次候选人的累计总得票数，根据指定的投票轮次
     * Total number of votes obtained from candidates
     */
    function fetchVoteNumForCandidate(
        address candidateAddr
    ) onlyVoteAfterOpen public constant returns (
        uint num
    ){
        return fetchVoteNumForCandidateBySnapshotBlock(candidateAddr,currentSnapshotBlock);
    }
    /**
     * 获取候选人指定轮次的投票详细情况
     */
    function fetchVoteResultForCandidateBySnapshotBlock(
       address candidateAddr,
       uint _snapshotBlock
    ) onlyVoteAfterOpen public constant returns (
        address[] addrs,
        uint[] nums
    ){
        uint voteRoundIndex = voteRoundIndexMap[_snapshotBlock];
        if(voteRoundIndex==0){
            require(_snapshotBlock==voteRounds[0].snapshotBlock);
        }
        uint index = voteRounds[voteRoundIndex].candidateIndexMap[candidateAddr];
        require(index>0);
        // 如果候选人存在,即时更新竞选情况 If candidates exist, update the campaign immediately.
        uint vcvl = voteRounds[voteRoundIndex].candidateArray[index].voterMapAddrs.length-1;
        address[] memory _addrs = new address[](vcvl);
        uint[] memory _nums = new uint[](vcvl);
        for(uint i = 1;i<=vcvl;i++){
            _nums[i-1]=voteRounds[voteRoundIndex].candidateArray[index].voterMap[
                voteRounds[voteRoundIndex].candidateArray[index].voterMapAddrs[i]
            ];
            _addrs[i-1]=voteRounds[voteRoundIndex].candidateArray[index].voterMapAddrs[i];
        }
        return (_addrs,_nums);
    }
    /**
     * 获取当前轮次候选人的投票详细情况 
     */
    function fetchVoteResultForCandidate(
        address candidateAddr
    ) onlyVoteAfterOpen public constant returns (
        address[] addr,
        uint[] nums
    ){
        return fetchVoteResultForCandidateBySnapshotBlock(candidateAddr,currentSnapshotBlock);
    }
    /**
     * 获取指定轮次候选人所有得票情况
     */
    function fetchAllVoteResultBySnapshotBlock(
        uint _snapshotBlock
    ) onlyVoteAfterOpen public constant returns (
        address[] addrs,
        uint[] nums
    ){
        uint voteRoundIndex = voteRoundIndexMap[_snapshotBlock];
        if(voteRoundIndex==0){
            require(_snapshotBlock==voteRounds[0].snapshotBlock);
        }
        require(voteRounds[voteRoundIndex].candidateArray.length>1);
        uint vcl = voteRounds[voteRoundIndex].candidateArray.length-1;
        address[] memory _addrs = new address[](vcl);
        uint[] memory _nums = new uint[](vcl);
        for (uint i = 1;i<=vcl;i++){
            _addrs[i-1]=voteRounds[voteRoundIndex].candidateArray[i].candidateAddr;
            _nums[i-1]=voteRounds[voteRoundIndex].candidateArray[i].numberOfVotes;
        }
        return (_addrs,_nums);
    }
    /**
     * 获取指定轮次的前一个轮次（轮次）候选人所有得票情况
     * 如果更新了地址，返回的是更新的地址数据
     */
    function fechAllVoteResultPreRoundByBlock(
        uint _block
    ) onlyVoteAfterOpen public constant returns (
       uint fromBlock,
       uint toBlock,
       address[] addrs,
       uint[] nums
    ){
        uint voteRoundIndex = voteRoundIndexMap[currentSnapshotBlock];
        if(voteRoundIndex<=round){
            return (0,0,new address[](0),new uint[](0));
        }
        if(_block>=voteRounds[voteRoundIndex].createSnapshotBlock){
            if(voteRoundIndex<2){
                return (0,0,new address[](0),new uint[](0));
            } else if(voteRounds[voteRoundIndex-1].candidateArray.length<2){
                return (0,0,new address[](0),new uint[](0));
            } else {
                uint vcl = voteRounds[voteRoundIndex-1].candidateArray.length-1;
                address[] memory _addrs = new address[](vcl);
                uint[] memory _nums = new uint[](vcl);
                for (uint i = 1;i<=vcl;i++){
                    _addrs[i-1]=voteRounds[voteRoundIndex-1].candidateArray[i].candidateAddr;
                    _nums[i-1]=voteRounds[voteRoundIndex-1].candidateArray[i].numberOfVotes;
                }
                return (
                    voteRounds[voteRoundIndex-1].createSnapshotBlock,
		            voteRounds[voteRoundIndex].createSnapshotBlock,
		            _addrs,
		            _nums
		        );
            }
        } else {
            return (0,0,new address[](0),new uint[](0));
        }
    }
    /**
     * 获取当前轮次候选人所有得票情况
     */
    function fetchAllVoteResultForCurrent(
    ) onlyVoteAfterOpen public constant returns (
        address[] addrs,
        uint[] nums
    ){
        return fetchAllVoteResultBySnapshotBlock(currentSnapshotBlock);
    }
    
}