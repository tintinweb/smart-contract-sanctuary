pragma solidity ^0.4.25;

contract HpbBallot {
    
    string public name = "HpbBallot";//票池名称
    
    uint public version = 1;//当前票池的版本号
    
    uint public round = 6;//选择总共几轮的数据作为选举结果，默认值为6，就是7轮数据的累计得票数为选举结果
    
    bool public activated=true;//投票合约是否激活，默认为已激活
    /**
     * 候选者的结构体
     */
    struct Candidate{
        address candidateAddr;//候选人账户地址
        
        address gainAddr;//候选人收益账户
        
        uint numberOfVotes;//得票数
        
        address[] voterMapAddrs;//对候选者投票的投票者数组，用于遍历用途
        
        mapping (address => uint) voterMap;//已经投票了投票人账户地址-》投票数
        
        mapping (address => uint) voterMapAddrsIndex;//投票人账户地址-》投票者数组(voterMapAddrs)下标
    }
    /**
     * 投票结构体
     */
    struct Voter{
        address voterAddr;//投票人的账户地址
        
        uint snapshotBalance;//快照余额
        
        uint voteNumber;//投票人已经投票数(实际投票数)
        
        address[] candidateMapAddrs;//用于遍历投票了的候选者用途
        
        mapping (address => uint) candidateMap;//已经投票了的候选者账户地址-》投票数
    }
    /**
     * 轮次投票结构体
     * 为了便于持续性投票，一般会每天随机选取一个已存在的区块号作为快照重新设置投票余额,
     * 这样就会重新计算实际生效的投票数额，让用户可以持续性参与投票
     */
    struct VoteRound{
        uint snapshotBlock;//每变换一次投票余额对应的区块快照号(切换投票轮次)
        
        uint createSnapshotBlock;//设置切换轮次操作所对应的区块号
        
        Candidate[] candidateArray;//候选者的数组
        /*
         * 候选者的地址与以上变量候选者数组(candidateArray)索引(数组下标)对应关系,用于查询候选者用途
         * 这样可以降低每次遍历对象对gas的消耗，存储空间申请和申请次数远远小于查询次数，并且计票步骤更加复杂，相比较消耗gas更多
         */
        mapping (address => uint) candidateIndexMap;
        
        Voter[] voterArray;//投票者数组
        
        mapping (address => uint) voterIndexMap;//投票者的地址与投票者序号(voterArray下标)对应关系，便于查询和减少gas消耗
    }
    /**
     * 初始化投票结构体，每变换一次投票余额对应的区块快照号(切换投票次)，就要对投票信息进行初始化操作，
     * 对前一个轮次的投票数据依据新投票余额快照号重新计算，然后初始化到当前轮次,便于持续性投票功能
     */
    struct InitVote{
        uint nextSnapshotBlock;//设置下一轮投票余额快照号
        
        bool hasPreVote;//是否已经对上一轮的数据重新计算，然后初始化到当前轮次(用于投票的持续性)
        
        bool hasSetNextVoterBalance;//是否完成设置下一阶段对应的投票者快照余额
        
        uint preSetNextVoterBalanceNum;//每次设置下一阶段对应的投票者快照余额账户个数(分批次设置，防止gas超限而失败)
        
        uint preVoteNum;//每次代投账户个数(分批次设置，防止gas超限而失败)
        
        uint preSetNextVoterBalanceIndex;//记录上一次设置的账户下标
        
        uint preVoteIndex;//记录上一次代投的账户下标
        
        mapping (address => uint) nextVoterBalance;//缓存投票者下一个轮次投票余额,投票者地址-》投票者快照投票余额
    }
    
    VoteRound[] public voteRounds;//分轮次投票
    
    mapping (uint => uint) voteRoundIndexMap;//轮次快照号对应的轮次号(VoteRound的下标)
    
    uint public currentSnapshotBlock;//当前轮次快照号
    
    InitVote initVote=InitVote(0,true,true,320,10000,1,1);//初始化投票信息
    
    address public owner;//HPB首席管理员(合约拥有者，可以基金会掌握)
    
    mapping (address => address) public adminMap;//管理员，用于切换轮次和设置快照余额
    
    uint[] public candidateIndexArray;//最终选举出的候选人下标，便于查询
    
    uint public capacity;//最终获选者总数(容量，获选者数量上限)
    
    event CandidateAdded(address indexed candidateAddr);//增加候选者
    
    event CandidateUpdated(address indexed candidateAddr);//更新候选者
    
    event CandidateDeleted(address indexed candidateAddr);//删除候选者
    
    /**
     * 票和撤销投票日志，flag：0撤销，1投票
     */
    event DoVoted(
        uint indexed index ,
        address indexed voteAddr,
        address indexed candidateAddr,
        uint num,
        uint flag
    );
    /**
     * 改变投票区间值,改变保证金最少金额,改变投票版本号
     */
    event CreateContract(
        uint indexed version,
        uint capacity
    );
    /**
     * 更新轮次轮次
     */
    event ChangeRoundBlock(
        uint indexed preRoundBlock,
        uint indexed stageBlock
    );
    /**
     * 设置快照余额
     */
    event SetSnapshotBalance(
        uint indexed voteRoundIndex,
        address indexed voterAddr,
        uint _snapshotBalance
    );
    /**
     * 对上一轮的自动持续性投票用途
     */
    event PreVoteNoLockByAdmin(
        address indexed voterAddr,
        address indexed candidateAddr,
        uint num
    );
    /**
     * 记录发送HPB的发送者地址和发送的金额
     */
    event ReceivedHpb(
        address indexed sender, 
        uint amount
    );
    /**
     * 未了持续性投票，每次切换新一轮快照余额的时候会对前一轮投票的数据复制到当前轮次中来，保证持续性的投票
     */
    modifier onlyPreVoteAfter{
        require(initVote.hasPreVote == true);
        _;
    }
    modifier onlyActivated{
        require(activated == true);
        _;
    }
    /**
     * 只有HPB首席管理员可以调用
     */
    modifier onlyOwner{
        require(msg.sender == owner);
        //Do not forfetch the "_;"! It will be replaced by the actual function
        //body when the modifier is used.
        _;
    }
    /**
     * 必须是管理员才能切换轮次和设置快照余额
     */
    modifier onlyAdmin{
        require(adminMap[msg.sender] != 0);
        _;
    }
    /**
     * 接受HPB转账，比如投票应用赞助(用于自动投票支出)
     */ 
    function () payable  external{
        emit ReceivedHpb(msg.sender, msg.value);
    }
    
    function transferOwnership(address newOwner) onlyOwner public{
        owner = newOwner;
    }
    function activateCotract() onlyOwner public{
        activated = true;
    }
    function deactivateCotract() onlyOwner public{
        activated = false;
    }
    function setCapacity(uint _capacity) onlyActivated onlyOwner public{
        capacity = _capacity;
    }
    
    /**
     * 增加普通管理员(管理合约，比如设置快照余额权利)
     */
    function addAdmin(address addr) onlyOwner public{
        require(adminMap[addr]== 0);
        adminMap[addr] = addr;
    }
    /**
     * 删除普通管理员
     */
    function deleteAdmin(address addr) onlyOwner public{
        require(adminMap[addr] != 0);
        adminMap[addr]=0;
    }
    /**
     * 设置选举结果的截止轮数(经过几轮投票就可出选举结果)
     */
    function setRound(uint _round) onlyActivated onlyOwner public{
        uint _voteRoundIndex = voteRoundIndexMap[currentSnapshotBlock];
        require(_round>_voteRoundIndex);
        round=_round;
    }
    /**
     * @param _preVoteNum 每次代投账户个数(分批次设置，防止gas超限而失败)
     */
    function setPreVoteNum(uint _preVoteNum) onlyActivated onlyOwner public{
        initVote.preVoteNum=_preVoteNum;
    }
    /**
     * @param _preSetNextVoterBalanceNum 每次设置下一阶段对应的投票者快照余额账户个数(分批次设置，防止gas超限而失败)
     */
    function setPreSetNextVoterBalanceNum(uint _preSetNextVoterBalanceNum) onlyActivated onlyOwner public{
        initVote.preSetNextVoterBalanceNum=_preSetNextVoterBalanceNum;
    }
    /**
     * 构造函数 
     */
    constructor(
        uint _version,//当前票池的版本号
        uint _capacity//获选者总量
    )payable public{
        owner = msg.sender;
        capacity=_capacity;
        version=_version;
        
        adminMap[owner]=owner;//设置默认普通管理员(合约创建者)
        currentSnapshotBlock=block.number;//设置首轮次区块快照号为当前区块号
        
        voteRounds.length++;
        voteRoundIndexMap[currentSnapshotBlock]=0;
        voteRounds[0].snapshotBlock=block.number;
        voteRounds[0].createSnapshotBlock=block.number;
        voteRounds[0].voterIndexMap[msg.sender]=0;
        /**
         * 设置第一个位置(为了定位不出错，第一个位置不占用)
         */
        voteRounds[0].voterArray.push(
            Voter(msg.sender,0,0,new address[](0))
        );
        voteRounds[0].candidateIndexMap[msg.sender]=0;
        /**
         * 设置第一位置(为了定位不出错，第一个位置不占用)
         */
        voteRounds[0].candidateArray.push(
            Candidate(msg.sender,0,0,new address[](0))
        );
        emit CreateContract(_version,_capacity);
    }
  
    /**
     * 添加候选者 ,必须首轮才可以添加候选人
     * @param _candidateAddr 候选者名称账户地址
     */
    function addCandidate(
        address _candidateAddr
    ) onlyActivated onlyAdmin public{
        require(voteRoundIndexMap[currentSnapshotBlock]==0);//必须首轮才可以添加候选人
        uint index = voteRounds[0].candidateIndexMap[_candidateAddr];
        require(index == 0);//必须候选人地址还未添加
        index = voteRounds[0].candidateArray.length;
        voteRounds[0].candidateIndexMap[_candidateAddr]=index;
        //默认收益地址为候选人账户地址
        voteRounds[0].candidateArray.push(Candidate(_candidateAddr,_candidateAddr,0,new address[](0)));
        voteRounds[0].candidateArray[index].voterMapAddrs.push(msg.sender);
        emit CandidateAdded(_candidateAddr);
    }
    
    /**
     * 批量添加候选者 
     * @param _candidateAddrs 候选者名称账户地址数组
     */
    function addCandidateBatch(
        address[] _candidateAddrs
    ) onlyActivated onlyAdmin public{
        for(uint i = 0;i<_candidateAddrs.length;i++){
            addCandidate(_candidateAddrs[i]);
        }
    }
    /**
     * 更新候选者收益地址
     * @param _candidateAddr 候选者账户地址 
     * @param _gainAddr 候选者收益账户地址 
     */
    function updateCandidateGainAddr(
        address _candidateAddr,
        address _gainAddr
    ) onlyActivated onlyOwner public{
        uint voteRoundIndex = voteRoundIndexMap[currentSnapshotBlock];
        uint index = voteRounds[voteRoundIndex].candidateIndexMap[_candidateAddr];
        require(index!= 0);//候选者必须存在
        voteRounds[voteRoundIndex].candidateArray[index].gainAddr=_gainAddr;
    }
    /**
     * 删除候选者 (一般不会删除，除非出现重大意外，删除候选人后，投的票全部退回)
     * @param _candidateAddr 候选者账户地址 
     */
    function deleteCandidate(
        address _candidateAddr
    ) onlyActivated onlyOwner public{
        uint voteRoundIndex = voteRoundIndexMap[currentSnapshotBlock];
        uint index = voteRounds[voteRoundIndex].candidateIndexMap[_candidateAddr];
        require(index!= 0);//候选者必须存在
        /**
         * 删除该候选者对应的投票者关联的候选者信息
         */
        for(uint n = 1;n<voteRounds[voteRoundIndex].candidateArray[index].voterMapAddrs.length;n++){
            /** 得到投票者  */
            uint voterIndex = voteRounds[voteRoundIndex].voterIndexMap[
                voteRounds[voteRoundIndex].candidateArray[index].voterMapAddrs[n]
            ];
            uint cindex = 0;
            /** 遍历对应投票者里面的候选者信息，并删除其中对应的该候选者 */
            for(uint k = 1;k<voteRounds[voteRoundIndex].voterArray[voterIndex].candidateMapAddrs.length-1;k++){
                if(cindex==0&&voteRounds[voteRoundIndex].voterArray[voterIndex].candidateMapAddrs[k]==_candidateAddr){
                    cindex=k;//得到候选者所处投票者结构体中的位置
                }
                if(cindex>0&&k>=cindex){//如果投票者结构体中候选者存在 
                    voteRounds[voteRoundIndex].voterArray[voterIndex].candidateMapAddrs[k]=
	                voteRounds[voteRoundIndex].voterArray[voterIndex].candidateMapAddrs[k+1];
                }
            }
            uint hasVoteNum=voteRounds[voteRoundIndex].voterArray[voterIndex].candidateMap[_candidateAddr];//撤回已经投的票
            if(hasVoteNum>0){
	            voteRounds[voteRoundIndex].voterArray[voterIndex].voteNumber=_safeSub(
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
    /**
     * 设置下一个轮次的快照区块号
     * @param _nextSnapshotBlock 下一轮次的快照区块号
     */
    function setNextSnapshotBlock(
        uint _nextSnapshotBlock
    ) onlyActivated onlyAdmin onlyPreVoteAfter public returns (
        bool _hasSetNextVoterBalance
    ){
        initVote.nextSnapshotBlock=_nextSnapshotBlock;
        initVote.preVoteIndex==1;
        return _preSetNextSnapshotBalance(initVote.preSetNextVoterBalanceNum);
    }
    /**
     * 管理员批量设置下一个轮次的投票者的快照余额
     * @param _preSetNextVoterBalanceNum 每次设置多少个
     */
    function _preSetNextSnapshotBalanceByAdmin(
        uint _preSetNextVoterBalanceNum
    ) onlyActivated onlyAdmin onlyPreVoteAfter public returns (
        bool _hasSetNextVoterBalance
    ){
        return _preSetNextSnapshotBalance(_preSetNextVoterBalanceNum);
    }
    /**
     * 批量设置下一个轮次的投票者的快照余额,供内部调用
     * @param _preSetNextVoterBalanceNum 每次设置多少个
     */
    function _preSetNextSnapshotBalance(
        uint _preSetNextVoterBalanceNum
    ) onlyActivated onlyAdmin onlyPreVoteAfter internal returns (
        bool _hasSetNextVoterBalance
    ){
	    require(_preSetNextVoterBalanceNum>0);
        if(initVote.preSetNextVoterBalanceIndex==1&&initVote.hasSetNextVoterBalance==true){
           initVote.hasSetNextVoterBalance=false;
        }
        if(initVote.hasSetNextVoterBalance==false){
	        uint voteRoundIndex = voteRoundIndexMap[currentSnapshotBlock];
	        require(voteRounds[voteRoundIndex].voterArray.length>1);
	        uint cl = voteRounds[voteRoundIndex].voterArray.length-1;
	        uint toIndex=_safeAdd(initVote.preSetNextVoterBalanceIndex,_preSetNextVoterBalanceNum);
	        if(toIndex>=cl){
	            toIndex=cl;
	            initVote.hasSetNextVoterBalance=true;
	        }else{
	            initVote.preSetNextVoterBalanceIndex=toIndex+1;
	        }
	        for(uint i =initVote.preSetNextVoterBalanceIndex;i<=toIndex;i++){
	           if(voteRounds[voteRoundIndex].voterArray[i].voteNumber>0){
		           initVote.nextVoterBalance[
		               voteRounds[voteRoundIndex].voterArray[i].voterAddr
		           ]=voteRounds[voteRoundIndex].voterArray[i].voterAddr.balance;
	           }
	        }
        }
        return initVote.hasSetNextVoterBalance;
    }
    /**
     * 获取下一轮次的快照区块号
     */
    function fetchNextSnapshotBlock(
    ) onlyActivated onlyAdmin public constant returns (
        uint nextSnapshotBlock
    ){
        return initVote.nextSnapshotBlock;
    }
    /**
     * 更新轮次(切换新余额快照号,重新计算投票余额和投票数)
     */
    function changeRoundBlock(
    ) onlyActivated onlyAdmin public returns (
        bool _hasPreVote
    ){
        require(initVote.nextSnapshotBlock!=0);
        uint _snapshotBlock = initVote.nextSnapshotBlock;
        require(currentSnapshotBlock<_snapshotBlock);
        uint _voteRoundIndex =voteRoundIndexMap[currentSnapshotBlock];//获取当前轮次的位置(序号)
        voteRounds.length++;
        currentSnapshotBlock=_snapshotBlock;
        voteRoundIndexMap[_snapshotBlock]=_voteRoundIndex+1;
        voteRounds[_voteRoundIndex].snapshotBlock=_snapshotBlock;
        voteRounds[_voteRoundIndex].createSnapshotBlock=block.number;
        voteRounds[_voteRoundIndex].voterIndexMap[msg.sender]=0;
        
        voteRounds[_voteRoundIndex].voterArray.push(//设置第一位置
            Voter(msg.sender,0,0,new address[](0))
        );
        if(_voteRoundIndex>round){//如果当前轮次复制选出的候选者
	        if(_voteRoundIndex==round+1){
	        	_calVoteResult();
	        }
            require(candidateIndexArray.length>0);
            voteRounds[_voteRoundIndex].candidateArray.push(//设置第一位置
                Candidate(msg.sender,msg.sender,0,new address[](0))
            );
            voteRounds[_voteRoundIndex].candidateIndexMap[msg.sender]=0;
            for(uint m = 0;m<candidateIndexArray.length;m++){
                voteRounds[_voteRoundIndex].candidateArray.push(
                    Candidate(
                        voteRounds[0].candidateArray[
                            candidateIndexArray[m]
                        ].candidateAddr,
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
                ]=_safeAdd(m,1);
                voteRounds[_voteRoundIndex].candidateArray[
                    _safeAdd(m,1)
                ].voterMapAddrs.push(msg.sender);
            }
        } else {
            for(uint k = 0;k<voteRounds[0].candidateArray.length;k++){//竞选轮次轮次
                voteRounds[_voteRoundIndex].candidateArray.push(
                    Candidate(
                        voteRounds[0].candidateArray[k].candidateAddr,
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
        emit ChangeRoundBlock(voteRounds[_voteRoundIndex-1].snapshotBlock,_snapshotBlock);
        return _preVoteNoLock(initVote.preVoteNum);
    }
    /**
     * 批量重新计算新一轮投票
     * @param _preVoteNum 每次批量重新计算新一轮投票的操作账户个数
     */
    function  _preVoteNoLockByAdmin(
        uint _preVoteNum
    )onlyActivated onlyAdmin public returns (
        bool _hasPreVote
    ){
        return _preVoteNoLock(_preVoteNum);
    }

    /**
     * 用于重新计票，根据前一个轮次的投票记录程序计票投票
     * @param _preVoteNum 每次批量重新计算新一轮投票的操作账户个数
     */
    function  _preVoteNoLock(
        uint _preVoteNum
    )onlyActivated onlyAdmin internal returns (
        bool _hasPreVote
    ){
        require(_preVoteNum>0);
	    uint toIndex=_safeAdd(_preVoteNum,initVote.preVoteIndex);
        uint voteRoundIndex = voteRoundIndexMap[currentSnapshotBlock];
        require(voteRoundIndex!=0);
        uint preRoundIndex = voteRoundIndex-1;
        uint cl = voteRounds[preRoundIndex].voterArray.length-1;
        if(initVote.preVoteIndex==1&&initVote.hasPreVote==true){
            initVote.hasPreVote=false;
        }
        if(initVote.hasSetNextVoterBalance==false){
	        if(toIndex>=cl){
	            toIndex=cl;
	            initVote.hasPreVote=true;
	        	initVote.nextSnapshotBlock=0;
	        	initVote.preSetNextVoterBalanceIndex=1;
	        }else{
	            initVote.preVoteIndex=toIndex+1;
	        }
	        for(uint i = initVote.preVoteIndex;i<=toIndex;i++){
	            uint bl = initVote.nextVoterBalance[
	                voteRounds[preRoundIndex].voterArray[i].voterAddr
	            ];
	            if(bl>0){
	            	uint voteNumber = voteRounds[preRoundIndex].voterArray[i].voteNumber;
	                if(voteNumber>0){
		                //设置权重(比例)
		                uint proportion = 100000;
		                if(voteNumber>bl){
		                    proportion=_safeMul(bl,proportion)/voteNumber;
		                }
		                //设置快照余额
		                setSnapshotBalance(voteRounds[preRoundIndex].voterArray[i].voterAddr,bl);
		                uint vvcl = voteRounds[preRoundIndex].voterArray[i].candidateMapAddrs.length;
		                //遍历候选者
		                for(uint k = 1;k<vvcl;i++){
		                    address _candidateAddr = voteRounds[preRoundIndex].voterArray[i].candidateMapAddrs[k];
		                    uint _candidateIndex = voteRounds[voteRoundIndex].candidateIndexMap[_candidateAddr];
					        //候选人必须存在
					        if(_candidateIndex!=0){
			                    uint num = voteRounds[preRoundIndex].voterArray[i].candidateMap[_candidateAddr];
			                    num = _safeMul(num,proportion)/100000;
			                    if(num>10000000000){
			                        emit PreVoteNoLockByAdmin(
			                            voteRounds[preRoundIndex].voterArray[i].voterAddr,
			                        	_candidateAddr,
			                        	num
			                        );
			                        _doVote(_candidateAddr,voteRoundIndex,num);
			                    }
					        }
		                }
	                }
	            }
	        }
        }
        return initVote.hasPreVote;
    }
    /**
     * 撤回当前轮次对某个候选人的投票 
     * @param candidateAddr 候选人账户地址
     * @param num 撤回的票数
     */
    function cancelVoteForCandidate(
        address candidateAddr,
    	uint num
    ) public{
        address voterAddr = msg.sender;
        uint voteRoundIndex = voteRoundIndexMap[currentSnapshotBlock];
        uint index = voteRounds[voteRoundIndex].voterIndexMap[voterAddr];
        require(index!=0);//必须投过票
        uint candidateIndex = voteRounds[voteRoundIndex].candidateIndexMap[candidateAddr];
        require(candidateIndex!=0);//候选人必须存在 
        uint cnum = voteRounds[voteRoundIndex].voterArray[index].candidateMap[candidateAddr];
        require(cnum>=num);//必须已投候选者票数不少于取消数量
        voteRounds[voteRoundIndex].candidateArray[candidateIndex].voterMap[voterAddr]=_safeSub(cnum,num);//处理候选者中的投票信息
        voteRounds[voteRoundIndex].candidateArray[candidateIndex].numberOfVotes=_safeSub(
            voteRounds[voteRoundIndex].candidateArray[candidateIndex].numberOfVotes,num
        );
        voteRounds[voteRoundIndex].voterArray[index].candidateMap[candidateAddr]=_safeSub(cnum,num);//处理投票者里面的投票信息
        voteRounds[voteRoundIndex].voterArray[index].voteNumber=_safeSub(
            voteRounds[voteRoundIndex].voterArray[index].voteNumber,num
        );
        emit DoVoted(voteRoundIndex,voterAddr,candidateAddr,num,0);
    }
    /**
     * 设置投票人的快照余额(以指定的区块号为准，到时候由官方或者HPB基金会对外公布)
     *  @param voterAddr 投票者账户地址
     *  @param _snapshotBalance 快照余额值
     */
    function  setSnapshotBalance(
        address voterAddr,
    	uint _snapshotBalance
    )onlyActivated onlyAdmin public{
        require(_snapshotBalance>0);
        uint voteRoundIndex = voteRoundIndexMap[currentSnapshotBlock];
        uint index = voteRounds[voteRoundIndex].voterIndexMap[voterAddr];
        if(index==0){//如果从没投过票，就添加投票人
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
    /**
     * 设置投票人下一个轮次的快照余额
     *  @param voterAddr 投票者账户地址
     *  @param _snapshotBalance 快照余额值
     */
    function  setNextSnapshotBalance(
        address voterAddr,
    	uint _snapshotBalance
    )onlyActivated onlyAdmin public{
        require(_snapshotBalance>0);
        require(initVote.nextSnapshotBlock!=0);
        initVote.nextVoterBalance[voterAddr]=_snapshotBalance;
    }
    /**
     * 得到某个投票者下一个轮次快照余额
     * @param voterAddr 投票者账户地址
     */
    function  getNextSnapshotBalance(
        address voterAddr
    )onlyActivated onlyAdmin public constant returns (
        uint _snapshotBalance
    ){
        return initVote.nextVoterBalance[voterAddr];
    }
    /**
     * 得到多个投票者下一个轮次快照余额
     * @param voterAddrs 投票者账户地址数组
     */
    function  getNextSnapshotBalanceOfMul(
        address[] voterAddrs
    )onlyActivated onlyAdmin public constant returns (
        uint[] _snapshotBalances
    ){
        uint cl=voterAddrs.length;
        uint[] memory snapshotBalances = new uint[](cl);
        for(uint i=0;i<cl;i++){
            snapshotBalances[i]=initVote.nextVoterBalance[voterAddrs[i]];
        }
        return snapshotBalances;
    }
    /**
     * 设置当前和下一个轮次的快照余额
     * @param voterAddr 投票者账户地址
     * @param _csnapshotBalance 当前轮次快照余额
     * @param _nsnapshotBalance 下一个轮次快照余额
     */
    function  setCurrentAndNextSnapshotBalance(
        address voterAddr,
    	uint _csnapshotBalance,
    	uint _nsnapshotBalance
    )onlyActivated onlyAdmin public{
        setSnapshotBalance(voterAddr,_csnapshotBalance);
        setNextSnapshotBalance(voterAddr,_nsnapshotBalance);
    }
    /**
     * 通过管理员批量投票
     * @param voterAddrs 投票者账户地址数组
     * @param candidateAddrs 候选者账户地址数组
     * @param _nums 投票数量数组
     */
    function voteByAdminBatch(
        address[] voterAddrs,
        address[] candidateAddrs,
    	uint[] _nums
    )onlyActivated onlyAdmin onlyPreVoteAfter public{
        uint voteRoundIndex = voteRoundIndexMap[currentSnapshotBlock];
        uint cl=voterAddrs.length;
        for(uint i=0;i<cl;i++){
	       uint index = voteRounds[voteRoundIndex].voterIndexMap[voterAddrs[i]];
	       require(index != 0);//必须设置过快照
	       require(_safeSub(//剩余的可投票数必须不少于投票数
	           voteRounds[voteRoundIndex].voterArray[index].snapshotBalance,
	           voteRounds[voteRoundIndex].voterArray[index].voteNumber
	       )>=_nums[i]);
	       _doVote(candidateAddrs[i],index,_nums[i]);
        }
    }

    /**
     * 用于非质押(锁定)投票 
     * @param candidateAddr 候选者账户地址
     * @param num 投票数量
     */
    function  voteNoLock(
        address candidateAddr,
    	uint num
    ) onlyPreVoteAfter public{
        //获取投票人的账户地址 fetch the address of the voters.
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
        uint voteRoundIndex = voteRoundIndexMap[currentSnapshotBlock];
        uint index = voteRounds[voteRoundIndex].voterIndexMap[voterAddr];
        //必须设置过快照
        require(index != 0);
        //剩余的可投票数必须不少于投票数
        require(_safeSub(
            voteRounds[voteRoundIndex].voterArray[index].snapshotBalance,
            voteRounds[voteRoundIndex].voterArray[index].voteNumber
        )>=num);
        _doVote(candidateAddr,index,num);
    }
    /**
     * 用于批量非质押(锁定)投票 
     * @param candidateAddrs 候选者账户地址数组
     * @param nums 投票数量数组
     */
    function  voteNoLockBatch(
        address[] candidateAddrs,
    	uint[] nums
    )onlyPreVoteAfter public{
        for(uint i = 0;i<candidateAddrs.length;i++){
            voteNoLock(candidateAddrs[i],nums[i]);
        }
    }
    /**
     * 执行投票 do vote
     * @param candidateAddr 候选者账户地址
     * @param index 投票者对象数组位置(下标)
     * @param num 投票数量
     */
    function _doVote(
        address candidateAddr,
        uint index,
    	uint num
    ) internal{
        require(num>0);
        uint voteRoundIndex = voteRoundIndexMap[currentSnapshotBlock];
        uint candidateIndex = voteRounds[voteRoundIndex].candidateIndexMap[candidateAddr];
        require(candidateIndex!=0);//候选人必须存在 
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
            ]=_safeAdd(
                voteRounds[voteRoundIndex].candidateArray[candidateIndex].voterMap[
                    voteRounds[voteRoundIndex].voterArray[index].voterAddr
                ],num
            );
            voteRounds[voteRoundIndex].voterArray[index].candidateMap[candidateAddr]=_safeAdd(
                voteRounds[voteRoundIndex].voterArray[index].candidateMap[candidateAddr],num
            );
        }
        /**投票人已投总数累加 */
        voteRounds[voteRoundIndex].voterArray[index].voteNumber=_safeAdd(
            voteRounds[voteRoundIndex].voterArray[index].voteNumber,num
        );
        /** 候选者得票数累加 */
        voteRounds[voteRoundIndex].candidateArray[candidateIndex].numberOfVotes=_safeAdd(
            voteRounds[voteRoundIndex].candidateArray[candidateIndex].numberOfVotes,num
        );
        emit DoVoted(voteRoundIndex,voteRounds[voteRoundIndex].voterArray[index].voterAddr,candidateAddr,num,1);
    }
    /**
     * 计算选举结果
     */
    function _calVoteResult(
    ) internal returns(
        address[] addr,
        uint[] nums
    ){
        require(voteRounds[round].candidateArray.length>1);
        uint vcl = voteRounds[round].candidateArray.length-1;
        Candidate[] memory _candidates = new Candidate[](vcl);
        for (uint i = 1;i<=vcl;i++){//取得第round轮的数据作为选举池
            _candidates[i-1]=Candidate(
                voteRounds[round].candidateArray[i].candidateAddr,
                voteRounds[round].candidateArray[i].candidateAddr,
                voteRounds[round].candidateArray[i].numberOfVotes,
                new address[](0)
            );
        }
        require(capacity<=_candidates.length);
        address[] memory _addrs = new address[](capacity);
        uint[] memory _nums = new uint[](capacity);
        uint min = _candidates[0].numberOfVotes;
        uint minIndex = 0;
        for (uint p = 0;p<_candidates.length;p++){
            if(p<capacity){//先初始化获选者数量池
                _addrs[p]=_candidates[p].candidateAddr;
                _nums[p]=_candidates[p].numberOfVotes;
                if(_nums[p]<min){//先记录获选者数量池中得票最少的记录 
                    min=_nums[p];
                    minIndex=p;
                }
            } else {
                if(_candidates[p].numberOfVotes==min){
                    /**对于得票相同的，取持币数量多的为当选
                     * if(_candidates[p].candidateAddr.balance>_addrs[minIndex].balance){
                     *     _addrs[minIndex]=_candidates[p].candidateAddr;
                     * 	   _nums[minIndex]=_candidates[p].numberOfVotes;
                     * }
                     */
                } else if(_candidates[p].numberOfVotes>min){
                    _addrs[minIndex]=_candidates[p].candidateAddr;
                    _nums[minIndex]=_candidates[p].numberOfVotes;
                    min=_nums[0];//重新记下最小得票者 
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
        for(uint n = 0;n<_addrs.length;n++){//记录下被选中的候选人
            candidateIndexArray.push(
                voteRounds[round].candidateIndexMap[_addrs[n]]
            );
        }
        return (_addrs,_nums);
    }
    /**
     * 获取指定轮次所有候选人的详细信息
     * @param _snapshotBlock 快照区块号
     */
    function fetchAllCandidatesBySnapshotBlock(
        uint _snapshotBlock
    ) public constant returns (
        address[] addrs
    ){
        uint voteRoundIndex = voteRoundIndexMap[_snapshotBlock];
        if(voteRoundIndex==0){
            require(_snapshotBlock==voteRounds[0].snapshotBlock);
        }
        require(voteRounds[voteRoundIndex].candidateArray.length>1);
        uint cl = voteRounds[voteRoundIndex].candidateArray.length-1;
        address[] memory _addrs = new address[](cl);
      
        for(uint i = 1;i<=cl;i++){
            _addrs[i-1]=voteRounds[voteRoundIndex].candidateArray[i].candidateAddr;

        }
        return (_addrs);
    }
    /**
     * 获取指定轮次所有投票人的详细信息
     * @param _snapshotBlock 快照区块号 
     */
    function fetchAllVotersBySnapshotBlock(
        uint _snapshotBlock
    ) public constant returns (
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
     * 得到最终投票选举结果 (必须是竞选完成后才能获取选举结果)
     * 该方法为常量方法，可以通过消息调用，如果更新了地址，返回的是更新的地址数据
     */
    function fetchVoteResult(
    ) public constant returns(
        address[] addr,
        uint[] nums
    ){
        uint cl = candidateIndexArray.length;
        require(cl>0);//必须是竞选完成后才能获取选举结果
        address[] memory _addrs = new address[](cl);
        uint[] memory _nums = new uint[](cl);
        for(uint m = 0;m<cl;m++){
            _addrs[m]=voteRounds[round].candidateArray[candidateIndexArray[m]].candidateAddr;
            _nums[m]=voteRounds[round].candidateArray[candidateIndexArray[m]].numberOfVotes;
        }
        return (_addrs,_nums);
    }
    /**
     * 得到投票者当前剩余票数和快照余额
     * @param voterAddr 投票者账户地址
     * @param _snapshotBlock 快照区块号
     */
    function fetchVoteMainInfoForVoterBySnapshotBlock(
        address voterAddr,
        uint _snapshotBlock
    ) public constant returns (
        uint snapshotBalance,
        uint voteNumber
    ){
        uint voteRoundIndex = voteRoundIndexMap[_snapshotBlock];
        if(voteRoundIndex==0){
            require(_snapshotBlock==voteRounds[0].snapshotBlock);
        }
        uint index = voteRounds[voteRoundIndex].voterIndexMap[voterAddr];
        if(index==0){ //没投过票 
            return (0,0);
        }
        return (
            voteRounds[voteRoundIndex].voterArray[index].snapshotBalance,
            voteRounds[voteRoundIndex].voterArray[index].voteNumber
        );
    }

    /**
     * 获取指定轮次投票人的所有投票情况 
     * @param voterAddr 投票者账户地址
     * @param _snapshotBlock 快照区块号
     */
    function fetchVoteInfoForVoterBySnapshotBlock(
        address voterAddr,
        uint _snapshotBlock
    ) public constant returns (
        address[] addrs,
        uint[] nums
    ){
        uint voteRoundIndex = voteRoundIndexMap[_snapshotBlock];
        if(voteRoundIndex==0){
            require(_snapshotBlock==voteRounds[0].snapshotBlock);
        }
        uint index = voteRounds[voteRoundIndex].voterIndexMap[voterAddr];
        if(index==0){ //没投过票 
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
     * @param _index 轮次序号
     */
    function fetchSnapshotBlockByIndex(
        uint _index
    ) public constant returns (
        uint _snapshotBlock
    ){
        return voteRounds[_index].snapshotBlock;
    }
    
    /**
     * 根据取得快照的区块号得到轮次序号
     * @param _snapshotBlock 快照区块号
     */
    function fetchRoundIndexBySnapshotBlock(
        uint _snapshotBlock
    ) public constant returns (
        uint _index
    ){
        return voteRoundIndexMap[_snapshotBlock];
    }
    /**
     * 得到当前轮次序号(轮次)
     */
    function fetchCurrentSnapshotBlockIndex(
    ) public constant returns (
        uint _index
    ){
        return voteRoundIndexMap[currentSnapshotBlock];
    }
    /**
     * 获取指定轮次候选人的总得票数，根据指定的投票轮次
     * @param candidateAddr 候选者账户地址
     * @param _snapshotBlock 快照区块号
     */
    function fetchVoteNumForCandidateBySnapshotBlock(
        address candidateAddr,
        uint _snapshotBlock
    ) public constant returns (
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
     * @param candidateAddr 候选者账户地址
     */
    function fetchVoteNumForCandidate(
        address candidateAddr
    ) public constant returns (
        uint num
    ){
        return fetchVoteNumForCandidateBySnapshotBlock(candidateAddr,currentSnapshotBlock);
    }
    /**
     * 获取候选人指定轮次的投票详细情况
     * @param candidateAddr 候选者账户地址
     * @param _snapshotBlock 快照区块号
     */
    function fetchVoteResultForCandidateBySnapshotBlock(
       address candidateAddr,
       uint _snapshotBlock
    ) public constant returns (
        address[] addrs,
        uint[] nums
    ){
        uint voteRoundIndex = voteRoundIndexMap[_snapshotBlock];
        if(voteRoundIndex==0){
            require(_snapshotBlock==voteRounds[0].snapshotBlock);
        }
        uint index = voteRounds[voteRoundIndex].candidateIndexMap[candidateAddr];
        require(index>0);
        //如果候选人存在,即时更新竞选情况 If candidates exist, update the campaign immediately.
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
     * @param candidateAddr 候选者账户地址
     */
    function fetchVoteResultForCandidate(
        address candidateAddr
    ) public constant returns (
        address[] addr,
        uint[] nums
    ){
        return fetchVoteResultForCandidateBySnapshotBlock(candidateAddr,currentSnapshotBlock);
    }
    /**
     * 获取指定轮次候选人所有得票情况
     * @param _snapshotBlock 快照区块号
     */
    function fetchAllVoteResultBySnapshotBlock(
        uint _snapshotBlock
    ) public constant returns (
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
     * 获取指定轮次的前一个轮次(轮次)候选人所有得票情况
     * 如果更新了地址，返回的是更新的地址数据
     * @param _block 奖励对应的区块号
     */
    function fechAllVoteResultPreRoundByBlock(
        uint _block
    ) public constant returns (
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
                    _addrs[i-1]=voteRounds[voteRoundIndex-1].candidateArray[i].gainAddr;
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
     * @param addrs 候选人账户地址数组
     * @param nums 得票数量数组
     */
    function fetchAllVoteResultForCurrent(
    ) public constant returns (
        address[] addrs,
        uint[] nums
    ){
        return fetchAllVoteResultBySnapshotBlock(currentSnapshotBlock);
    }
    
    uint256 constant MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    function _safeAdd(
        uint256 x,
        uint256 y
    ) internal pure returns (
        uint256 z
    ){
        if (x>MAX_UINT256-y) {
            revert();
        }
        return x+y;
    }
    function _safeSub(
        uint256 x, 
        uint256 y
    ) internal pure returns (
        uint256 z
    ){
        if (x<y){
            revert();
        }
        return x-y;
    }
    function _safeMul(
        uint256 x, 
        uint256 y
    ) internal pure returns (
        uint256 z
    ){
        if (y== 0){
            return 0;
        }
        if (x>MAX_UINT256 / y) {
            revert();
        }
        return x*y;
    }
}