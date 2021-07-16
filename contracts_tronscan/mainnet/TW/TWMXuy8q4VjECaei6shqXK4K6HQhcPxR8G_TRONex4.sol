//SourceUnit: tronex4.sol



pragma solidity ^0.5.8;




contract TRONex4 {
	using SafeMath for uint256;
	
	
	
	
	
	//-------------start~1----------------
	uint256 constant public INVEST_MIN_AMOUNT = 200 trx ;
	uint256 constant public  dynamic_min_investment = 100 trx ;
	uint256 constant public INVEST_MAX_AMOUNT = 50000 trx ;
	uint256 constant public BASE_PERCENT = 300;
	uint256[20] public REFERRAL_PERCENTS = [3000, 1000, 500, 500,500,300,300,300,300,300,200,200,200,200,200,100,100,100,100,100];
	uint256 constant public PROJECT_FEE = 500;
	uint256 constant public SMALL_NODE_FEE = 400;
	uint256 constant public PERCENTS_DIVIDER = 10000;
	uint256[6] public dynamicRate  = [5,6,7,8,9,10];
	//uint256[3] public dynamicEffectiveDeposit = [5000 trx,2500 trx,500 trx];
	uint256[3] public dynamicEffectiveDeposit = [10000 trx,5000 trx,1000 trx];
	//-------------end~1----------------
	

	
	
	//有效直推代数分别是0代，3代，10代，20代
	uint256[4] public effectiveDirectAlgebra = [0,3,10,20];
	
	//保障池状态,分红执行之后触发保障池
	bool public guaranteePoolStatus = false;
	
	
	//众筹项目地址
	Crowdsale public _crowdsale  ;
	
	//游戏3瓜分池子
	uint256 public divide3Pool;
	uint256 public divide3PoolCount;
	
	
	//保障池地址
	address payable public guaranteePoolAddress;
	address payable public game2Address;
	
	
	
	//-------------start~2----------------
	uint256 constant public CONTRACT_BALANCE_STEP = 100000 trx;

	//成为小节点要求的业绩阀值
	uint256 constant public SMALL_NODE_THRESHOLD = 200000 trx;
	
	uint256 constant public TIME_STEP = 1 days;

	uint256 constant public FOMO_TIME_STEP = 12 hours;
		
	uint256 constant public REMOVE_FOMO_LIMIT = 2000000 trx;
	//合约起始资金
	uint256 constant public STARTING_CAPITAL = 1000000 trx;
	uint256 constant public FOMO_LIMIT = 1000000 trx;	
	uint256 public divide3PoolLimit = 10000e6;
	//-------------end~2----------------
	
	

	
	
	address payable[13]  public referralRows13 = [
		address(0x41F0C91C04480BF51F99D3E00F8CFFCE396D2A5CE8),
		address(0x411CC4DB96EDBFD6CAE8EC3486A42F6AA5D622B5E6),
		address(0x41C3A42EB476443D1DCBC84D8C2EF1C4995C208748),
		address(0x417C57E548DE0530D9571B8FBABB264A42B56B5C57),
		address(0x417FA8F1A4D2DB76FECCEAF1FF9FF8A3BA270A9942),
		address(0x414E020513FFD20537460DB086F5458846083BBAE6),
		address(0x418EEF60E0DB585E6265BF6AD9743229ED6C4C2B81),
		address(0x413DD293E7B0C97921027C5EEC2871BB3A12377AAA),
		address(0x41AE57E063F3E42D637AFD3BC9CA6CF827EF681160),
		address(0x415BF4E93EE2FA9F1C2951ED17E5C93A1F5F6BD37C),
		address(0x419394BBD848B6CE446E4F8278236F18A936A2F345),
		address(0x412E4597F55EB7D9E953ED147B1148290AAAF5DFEA),
		address(0x418B76B73C9F0B151D004FC468DC4EAB69BB92D392)
	];
	
	mapping(address => bool) public referralMap; 
	
	address payable[12] public nodeAddress13 = [
		address(0x411C430C136BA019C6C04F20941B448F3C22F6C37C),
		address(0x417BFB82FDACE395CF063BD4FC75EE111C11222BD9),
		address(0x4120375CB0F6D1A33FA735FEF82C5BD8617FDF6797),
		address(0x4172C3C575A2D674F97EA9057B4D27F7077D056551),
		address(0x418EFAFD39D147ADD45DA5DD48353417BBCE4FE47D),
		address(0x419AA70BA2086AD21CB21494FD3451CFF3220548C2),
		address(0x41633B036DDEBB6A658CB78DBD06D4EE58D2907009),
		address(0x4117586116E18032FB496D31E1F7986FF19A1651B2),
		address(0x41ADF326133FCDA5F16521278698B1EE947F61862C),
		address(0x41235816BD91BF78C33A78520211A9B8091AB89E1A),
		address(0x41589C865ECEE8FDA62A59BB9274E38D8F437CA844),
		address(0x4161C35DC4BE49028D592583CDE5C33E618173540F)
	];
	
	
	uint256  public FOMO_STATUS = 1; 
	uint256  public FOMO_START_TIME = 0;	
	uint256 public resetTime = 0;
	uint256 public version = 0;
	
	
	
	uint256 constant public SUPER_NODE_LIMIT = 200000 trx;
		
	uint256  public projectStartTime ;

	uint256 public totalUsers = 0;
	uint256 public totalInvested;
	//uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint256 public lastUserId = 0;
			
	//address payable public handlingFeeAddress = address(0x4127741B2B3A0A3B0E390A3C6B78100F7AD274F741); 
	
	address payable internal referralAddress = address(0x415B6BE63641C2C3949FD5B958879C3255B36D8DCC);



	
	address payable public projectAddress = address(0x4161D36F6724AB037FB89799C3DD99A59996BD54BB);
	address payable public projectAddress2nd = address(0x418F9F239F5316BABA27D078A16EEE78AA0ABC8269);
	address payable public  owner;
	address payable private  _owner;
	
	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address payable referrer; 
		uint256 bonus; //奖励
		uint256 dynamicBaseInvestment; //动态基础投资
		uint256[20]  performance;   //20代业绩
		uint256   performances;
		uint256 effectiveReferences; //有效直推
		mapping(address => uint256) tMap;
		mapping(uint256 => uint256) t; //直推等级数量
		//mapping(address => bool) effectiveReferMap;
		address payable nodeAddr; //最近节点地址
		address payable smallNodeAddr;
		uint256 exceeded; //额外的	
		uint256 v; //用户版本
	}

	mapping (uint256 => uint256) internal rewardAlgebra; 

	mapping (address => User) public users;
	
	mapping (address => mapping(uint256 => uint256))  public userDayWithDraw;
	
	mapping(uint256 => address payable) public investmentRecord;
	
	mapping(uint256 => address) public registrationRecord;
	
	mapping(address => uint256) public nodeBonus;
	
	mapping (address => bool)  public superNode;
	mapping (uint => address payable)  public superNodeId;
	uint internal superNodeLength = 10;
	
	//用户静态提取
	mapping (address => uint256)  public userWithdraw;
	//用户动态提取
	mapping (address => uint256)  public userBonusWithdraw;
	

	event Newbie(address user);
	
	event InitInvest(uint256 indexed id, address user,address referrer,uint256 value);
	
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);


	event  Upgrade(address indexed user, uint256 totalAmount);

	//constructor(address crowdsaleAddress) public {
	
	
	
	
	//function setDynamicEffectiveDeposit(uint256 index , uint256 value) public {
	//	require(_owner == msg.sender,"Ownable: caller is not the owner");
	//	dynamicEffectiveDeposit[index] = value;
	//}
	
	
	constructor() public {
	
		
		owner = msg.sender;
		_owner = msg.sender;
		
	
		
	}
	
	function init0(address crowdsaleAddress) public onlyOwner{
		_crowdsale = Crowdsale(crowdsaleAddress);
		
		
		
		
		//_crowdsale = Crowdsale(0x41B650F6E5661EE13241B5F28EE31F463F752CED0E);
		
		
		// = address(0x4161D36F6724AB037FB89799C3DD99A59996BD54BB);
		//projectAddress2nd = address(0x418F9F239F5316BABA27D078A16EEE78AA0ABC8269);
		
		game2Address = address(0x41BDA93C309D7F7B1E6A2D8BB38996F61B4F48773E);
		guaranteePoolAddress  = address(0x41FDFB98FD83CD3A527517A47EC793D71B6AE9A984);
		
		rewardAlgebra[1] = 3;
		rewardAlgebra[2] = 10;
		rewardAlgebra[3] = 20;

		projectStartTime = block.timestamp;
	}
	
	function init1() public onlyOwner{
		//require(!isContract(referralAddr) && !isContract(projectAddr));
		//referralAddress = referralAddr;
		
		User storage user1st = users[referralAddress];
		user1st.deposits.push(Deposit(1 trx, 0, block.timestamp));
		user1st.effectiveReferences = 1;		
		registrationRecord[totalUsers] = referralAddress;
		totalUsers = totalUsers.add(1);		
		investmentRecord[lastUserId] = referralAddress;
		lastUserId++;
		referralMap[referralAddress] = true;
		
		User storage user2nd = users[referralRows13[0]];
		user2nd.referrer = referralAddress;
		user2nd.deposits.push(Deposit(1 trx, 0, block.timestamp));
		user2nd.effectiveReferences = 1;		
		registrationRecord[totalUsers] = referralRows13[0];
		totalUsers = totalUsers.add(1);		
		investmentRecord[lastUserId] = referralRows13[0];
		lastUserId++;
		
		referralMap[referralRows13[0]] = true;
		
	}
	
	uint256 private start_ = 0;
	function init2(uint256 start,uint256 end) public onlyOwner {
		
		//i :从1开始，最大13
		require(start >= start_ && start>=1 && end<=13);
		start_ = start;
		
		for(uint256 i = start;i<end;i++){		
			address referral =  referralRows13[i];
			User storage user3nd = users[referral];
			user3nd.referrer = referralRows13[i-1];
			user3nd.deposits.push(Deposit(1 trx, 0, block.timestamp));
			user3nd.effectiveReferences = 1;		
			registrationRecord[totalUsers] = referralRows13[i];
			totalUsers ++;		
			investmentRecord[lastUserId] = referralRows13[i];
			lastUserId++;
			referralMap[referral] = true;
		}
	}
	
	uint256 private _start = 0;
	function init3(uint256 start,uint256 end) public onlyOwner{
	
	
		//i :从0开始，最大12
		require(start >= _start && start>=0&& end<=12);
		_start = start;
	
		for(uint256 i = start;i<end;i++){
		
			address payable nodeAddr = nodeAddress13[i];
			User storage user = users[nodeAddr];
			
			superNode[nodeAddr] = true;
			
			user.checkpoint = block.timestamp;
			user.referrer = referralRows13[12];
			
			user.deposits.push(Deposit(1 trx, 0, block.timestamp));
			
			user.dynamicBaseInvestment = 1000000 trx;
			registrationRecord[totalUsers] = nodeAddr;
			totalUsers ++;
			
			investmentRecord[lastUserId] = nodeAddr;
			lastUserId++;
		}
		
		totalInvested = SUPER_NODE_LIMIT.mul(12);
		totalDeposits = SUPER_NODE_LIMIT.mul(12);
	}
	
	function()external payable { 
    	// some code
	}

	function invest(address payable referrer) public payable checkVersion {
		require(msg.value >= INVEST_MIN_AMOUNT);
		
	   
		require(!isContract(msg.sender),"Prohibit contract address investment");
		
		//直推有效用户
		uint256 _amount =  msg.value.add(getUserTotalDeposits(msg.sender));
		//单个账户最多可以累加投资5万trx
		
	
		//if(userWithdraw[msg.sender].mod(INVEST_MAX_AMOUNT) != 0 && userWithdraw[msg.sender].div(INVEST_MAX_AMOUNT).mod(2) != 0){
			require(_amount <= INVEST_MAX_AMOUNT,"Maximum investment of 50,000 trx");
		
		//}
		
		

		//项目方存款地址收款5%
		projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));

		//保障池5%
		TransferHelper.safeTransferTRX(guaranteePoolAddress,msg.value.mul(5).div(100));
		//游戏2池
		TransferHelper.safeTransferTRX(game2Address,msg.value.mul(1).div(100));
		
		
		
		
		//to-do日志
		
        divide3Pool = msg.value.div(100).add(divide3Pool);
		
		if(divide3Pool > divide3PoolLimit){
			divide3PoolCount = lastUserId;
		}
		
		//emit FeePayed(msg.sender, msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));

		User storage user = users[msg.sender];
		address payable _nodeaddr = users[referrer].nodeAddr;
	
		
		if (user.referrer == address(0)  && referrer != msg.sender) {
			if(users[referrer].v >0 || users[referrer].deposits.length > 0){
				user.referrer = referrer;
				if(superNode[referrer]){
					user.nodeAddr = referrer;
				}else if(_nodeaddr != address(0) && superNode[_nodeaddr]){
					user.nodeAddr = _nodeaddr;
				}
			}	
		}
	
		
	
		//存款记录
		investmentRecord[lastUserId] = msg.sender;
		lastUserId ++;

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			if(user.v <1){
				registrationRecord[totalUsers] = msg.sender;
				totalUsers = totalUsers.add(1);
				emit Newbie(msg.sender);
			}

		}

		user.deposits.push(Deposit(msg.value, 0, block.timestamp));
		

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);
		
		//fomo板块
		if(address(this).balance >= FOMO_LIMIT){
			if(FOMO_STATUS == 1){
				FOMO_STATUS = 2;
			}else if(FOMO_STATUS == 3 && address(this).balance >= REMOVE_FOMO_LIMIT ){ 
				FOMO_START_TIME = 0;
				FOMO_STATUS = 2;
				version =  version.add(1);
			}			
		}
		//fomo板块 12小时时间不刷新
		//if(FOMO_STATUS == 3 && FOMO_START_TIME.add(TIME_STEP) > block.timestamp ){			
		//	FOMO_START_TIME = block.timestamp;
		//}else 
		//重置fomo时间
		if(FOMO_STATUS == 3 && FOMO_START_TIME.add(FOMO_TIME_STEP) < block.timestamp){
			require(FOMO_START_TIME.add(FOMO_TIME_STEP).add(180) >= block.timestamp);
			FOMO_START_TIME = block.timestamp.sub(FOMO_TIME_STEP);
		}
		
		address payable  _refer = users[msg.sender].referrer;
		
		//确定小节点
		if(user.smallNodeAddr == address(0) && users[_refer].smallNodeAddr != address(0)){
			user.smallNodeAddr = users[_refer].smallNodeAddr;
		}
		
		
		for(uint256 i = 0;i<20;i++){			
			//10个超级节点额外奖励
		//	if(i< 10){
		//		address _addr = superNodeId[i];
		//		users[_addr].bonus  = users[_addr].bonus.add(msg.value.mul(2).div(1000));
		//	}
			//给20代累计业绩
			if(_refer != address(0)){			    
    			users[_refer].performance[i]  = users[_refer].performance[i].add(msg.value);
			
				//确定小节点
				if(isSmallNode(_refer) && user.smallNodeAddr == address(0)){
					user.smallNodeAddr = _refer;
				}
				_refer = users[_refer].referrer;				
			} 
		}
	
				//更新
		updateDirectLevel(msg.sender);

			//小节点奖励
		if(user.smallNodeAddr != address(0)){
			user.smallNodeAddr.transfer(msg.value.mul(4).div(100));
			nodeBonus[user.smallNodeAddr] = nodeBonus[user.smallNodeAddr].add(msg.value.mul(SMALL_NODE_FEE).div(PERCENTS_DIVIDER));
			if(user.nodeAddr != address(0) ){
				user.nodeAddr.transfer(msg.value.mul(2).div(100));
				nodeBonus[user.nodeAddr] = nodeBonus[user.nodeAddr].add(msg.value.mul(200).div(PERCENTS_DIVIDER));
			}
		}else if(user.nodeAddr != address(0)){
			//大节点奖励
			user.nodeAddr.transfer(msg.value.mul(6).div(100));
			nodeBonus[user.nodeAddr] = nodeBonus[user.nodeAddr].add(msg.value.mul(600).div(PERCENTS_DIVIDER));
		}
		
		emit NewDeposit(msg.sender, msg.value);
	}

	function withdraw() public checkVersion{

		require(FOMO_STATUS != 3,"monopoly game stops withdrawing");
		

		User storage user = users[msg.sender];

		uint256 userPercentRate = getUserPercentRate(msg.sender);

		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {
				if (user.deposits[i].start >= user.checkpoint) {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
				} else {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);
				}	
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
					dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
				}								
				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);
			}
		}

		totalAmount = totalAmount.add(user.exceeded);	
		require(totalAmount > 0, "User has no dividends");
	
		uint256 _tolalDepos = getUserTotalDeposits(msg.sender);
		
		//require(userWithdraw[msg.sender] <= _tolalDepos.mul(2) );

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}else{		
			if(FOMO_STATUS == 3){
				require(contractBalance.sub(totalAmount) > FOMO_LIMIT,'fomo status cannot be extracted');
			}else if(FOMO_STATUS == 2){			
				if(contractBalance.sub(FOMO_LIMIT) < totalAmount){	
					user.exceeded = totalAmount.sub(contractBalance.sub(FOMO_LIMIT));				
					FOMO_START_TIME =  block.timestamp;
					FOMO_STATUS = 3;
					totalAmount = contractBalance.sub(FOMO_LIMIT);
				}
			}
		}

		user.checkpoint = block.timestamp;
		
		//if(totalAmount >= _tolalDepos.mul(2).sub(userWithdraw[msg.sender])){
		//	totalAmount =  _tolalDepos.mul(2).sub(userWithdraw[msg.sender]);	
		//}
		
		userWithdraw[msg.sender] = userWithdraw[msg.sender].add(totalAmount);
		
		if(totalAmount.add(userWithdraw[msg.sender]) > _tolalDepos ){			
			//手续费
			projectAddress2nd.transfer(totalAmount.mul(5).div(100));			
			totalAmount = totalAmount.mul(95).div(100);
		}
		
		msg.sender.transfer(totalAmount);
		//userWithdraw[msg.sender] = userWithdraw[msg.sender].add(totalAmount);
		
		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 20; i++) {
				if (upline != address(0)) {
					//当前等级
					uint256 effectiveRefNum = getEffectiveLevel(upline);
					if(effectiveRefNum == 0){
						upline = users[upline].referrer;
						continue;
					}
					if( rewardAlgebra[effectiveRefNum]>= (i+1)){
						uint256 amount = totalAmount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
						if(amount > 0){
							users[upline].bonus = users[upline].bonus.add(amount);
							emit RefBonus(upline, msg.sender, i, amount);							
						}else break;
					}					
				} else{
					break;
				}
				upline = users[upline].referrer;
			}
		}
		//totalWithdrawn = totalWithdrawn.add(totalAmount);
		emit Withdrawn(msg.sender, totalAmount);
	}
	
	//动态投资,主要针对于团队奖励
	function dynamicInvestment() public payable checkVersion{	
		require(msg.value.mod(100) == 0 &&msg.value >= dynamic_min_investment,"Dynamic minimum investment");
		User storage user  = users[msg.sender];
		if(user.dynamicBaseInvestment < 1){
			user.dynamicBaseInvestment =  msg.value.add(2500e6);
		}else{
			user.dynamicBaseInvestment = user.dynamicBaseInvestment.add(msg.value);
		}
		
		//监控资金池变化
		//fomo板块
		//项目地址收取5%手续费
		projectAddress.transfer(msg.value.mul(5).div(100));
		
		//保障池5%
		TransferHelper.safeTransferTRX(guaranteePoolAddress,msg.value.mul(5).div(100));
		//游戏2池
		TransferHelper.safeTransferTRX(game2Address,msg.value.mul(1).div(100));

        divide3Pool = msg.value.div(100).add(divide3Pool);
		
		if(divide3Pool > divide3PoolLimit){
			divide3PoolCount = lastUserId;
		}


		if(address(this).balance >= FOMO_LIMIT){
			if(FOMO_STATUS == 1){
				FOMO_STATUS = 2;
			}else if(FOMO_STATUS == 3 && address(this).balance >= REMOVE_FOMO_LIMIT ){ 
				FOMO_START_TIME = 0;
				FOMO_STATUS = 2;
				version =  version.add(1);
			}			
		}

			//小节点奖励
		if(user.smallNodeAddr != address(0)){
			user.smallNodeAddr.transfer(msg.value.mul(4).div(100));
			nodeBonus[user.smallNodeAddr] = nodeBonus[user.smallNodeAddr].add(msg.value.mul(SMALL_NODE_FEE).div(PERCENTS_DIVIDER));
			if(user.nodeAddr != address(0)){
				user.nodeAddr.transfer(msg.value.mul(2).div(100));
				nodeBonus[user.nodeAddr] = nodeBonus[user.nodeAddr].add(msg.value.mul(200).div(PERCENTS_DIVIDER));
			}
		}else if(user.nodeAddr != address(0)){
			//大节点奖励
			user.nodeAddr.transfer(msg.value.mul(6).div(100));
			nodeBonus[user.nodeAddr] = nodeBonus[user.nodeAddr].add(msg.value.mul(600).div(PERCENTS_DIVIDER));
		}
	
	}
	

	function getReferBonus() public checkVersion{	
		if(FOMO_STATUS == 3 ){
			require(false,"monopoly game stops withdrawing");
		}
		
		uint256 _referBonus = getUserReferralBonus(msg.sender);
		User storage  user = users[msg.sender];
		
		uint256 contractBalance = address(this).balance;
		if(FOMO_STATUS == 3){
			require(contractBalance.sub(FOMO_LIMIT) > _referBonus,'fomo status cannot be extracted');
		}else if(FOMO_STATUS == 2){			
			if(contractBalance.sub(FOMO_LIMIT) < _referBonus){
				FOMO_START_TIME =  block.timestamp;
				FOMO_STATUS = 3;
				_referBonus = contractBalance.sub(FOMO_LIMIT);
			}
		}
		uint256 dbi = getDynamicBaseInvestment(msg.sender);
		if(dbi.mul(4).sub(userBonusWithdraw[msg.sender]) <= _referBonus){
			_referBonus = dbi.mul(4).sub(userBonusWithdraw[msg.sender]);	
		}
	   //动态赔率
		
		projectAddress2nd.transfer(_referBonus.mul(dynamicWithdrawalRate(msg.sender)).div(100));
		
		//_referBonus = _referBonus.sub(_referBonus.mul(dynamicWithdrawalRate[msg.sender]).div(100));
		
		msg.sender.transfer(_referBonus.sub(_referBonus.mul(dynamicWithdrawalRate(msg.sender)).div(100)));
		
		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 20; i++) {
				if (upline != address(0)) {
					uint256 effectiveRefNum = getEffectiveLevel(upline);
					if(effectiveRefNum == 0){
						upline = users[upline].referrer;
						continue;
					}
					if( rewardAlgebra[effectiveRefNum]>= (i+1)){
						uint256 amount = _referBonus.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
						if(amount > 0){
							uint256 _bonus = users[upline].bonus.add(amount);
							if(getDynamicBaseInvestment(upline).mul(4).sub(userBonusWithdraw[upline]) <= _bonus){
								users[upline].bonus = getDynamicBaseInvestment(upline).mul(4).sub(userBonusWithdraw[upline]);
							}else{
								users[upline].bonus = _bonus;
							}							
							emit RefBonus(upline, msg.sender, i, amount);							
						}else break;
					}					
				}else{
					break;
				}
				upline = users[upline].referrer;
			}
		}
		userBonusWithdraw[msg.sender]= userBonusWithdraw[msg.sender].add(_referBonus);
		//totalWithdrawn = totalWithdrawn.add(_referBonus);
		users[msg.sender].bonus = 0;
	}
	
	
	
	uint256 internal fomoDividendId = 0;
	uint256 internal fomoDividendTime = 0;
	uint256 internal fomoDividendValue = 0;

	
	
	function executiveFomoDividendStatus() public view returns(bool){	
		if(FOMO_STATUS == 3 && block.timestamp > FOMO_START_TIME.add(FOMO_TIME_STEP).add(180)){
			return true;
		}else{
			return false;
		}
	}
	
	function executiveFomoDividend() public {
		require(FOMO_STATUS == 3);
		require(block.timestamp > FOMO_START_TIME.add(FOMO_TIME_STEP).add(180) );
		require(lastUserId > 10);
		fomoDividendId = lastUserId.sub(1);
		fomoDividendTime = block.timestamp;
		
		address payable user ;

		uint256 contractBalance = address(this).balance;
		
		projectAddress2nd.transfer(contractBalance.mul(5).div(100));
		
		contractBalance = contractBalance.mul(95).div(100);
		fomoDividendValue = contractBalance; 

		user = investmentRecord[lastUserId.sub(1)];
		user.transfer(contractBalance.mul(50).div(100));

		user = investmentRecord[(lastUserId.sub(2))];
		user.transfer(contractBalance.div(10));

		contractBalance  = contractBalance.sub(contractBalance.mul(50).div(100).add(contractBalance.div(10)));

		for(uint256 i = (lastUserId.sub(3));i >= lastUserId.sub(10);i-- ){
			user = investmentRecord[i] ;	
			user.transfer(contractBalance.div(8));	
		}
		//修改保障池状态
		guaranteePoolStatus =  true;
	}
	
	//最后10个分红地址
	function getLastTenDividenders() public view returns(address[10] memory luckers,uint256[10] memory values,uint256 time){
		if(fomoDividendId != 0 ){
			uint256 j = fomoDividendId.sub(1);
			for(uint256 i= 0;i <10;i++){
				luckers[i] = investmentRecord[j];
				j = j--;
			}
		}
		values[0] = fomoDividendValue.mul(50).div(100);
		values[1] = fomoDividendValue.div(10);
		for(uint256 k = 2;k<10;k++){
			values[k] = fomoDividendValue.mul(40).div(100).div(8);		
		}
		time = fomoDividendTime;
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}
	
	function getNodeList() public view returns (address[10] memory addr){
		if(superNodeLength >= 0){
			for(uint i = 0; i < superNodeLength;i++ ){
				address _addr = superNodeId[i];
				if(_addr != address(0)){
					addr[i] = superNodeId[i];
				}else break;			
			}
		}
	}
	
	function getPerformance(address _userAddr) public view returns(uint256[20] memory _performance){		
		if(users[_userAddr].v != version){
			if(superNode[_userAddr] || referralMap[_userAddr]){
				_performance = users[_userAddr].performance;
			}
		}else{
			_performance = users[_userAddr].performance;
		}
	}
	
	//查询累计20代业绩
	function getPerformances(address _userAddr) public view returns(uint256  performances){	
		uint256[20] memory _performance = users[_userAddr].performance;
		for(uint256 i = 0;i<20;i++){
			performances = performances.add(_performance[i]);
		}
	}

	function getContractBalanceRate() public view returns (uint256) {		 
		uint256 contractBalance = address(this).balance;
		uint256 contractBalancePercent = 0;
		if(contractBalance > STARTING_CAPITAL){
			contractBalancePercent = contractBalance.sub(STARTING_CAPITAL).div(CONTRACT_BALANCE_STEP);
		}

		
		uint256 rate =   BASE_PERCENT.add(contractBalancePercent);
		if(rate > 2000){
			rate = 2000;
		}
		return rate;		
	}

	function getUserPercentRate(address userAddress) public view returns (uint256) {
		return getContractBalanceRate();	
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User memory user = users[userAddress];



		if(user.v != version){
			if(superNode[userAddress] || referralMap[userAddress]){
			}else{
				return 0;
			}	
		}



		uint256 userPercentRate = getUserPercentRate(userAddress);

		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

				if (user.deposits[i].start >= user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);
				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
					dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);

				/// no update of withdrawn because that is view function
			}

		}	
		
		totalDividends = totalDividends.add(user.exceeded);

		return totalDividends;
	}
	


	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}
	
	function getLastTenParter() external  view  returns(address[10] memory addr) {	
		if(lastUserId>0){
			if(lastUserId>=10){
				for(uint256 i= 0;i<10;i++){
					addr[i] = investmentRecord[lastUserId.sub(1).sub(i)];
				}
			}else{
				for(uint256 i= 0;i < lastUserId.sub(1);i++){
						addr[i] = investmentRecord[lastUserId.sub(1).sub(i)];
					}
				}
		}
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}
	//获取用户动态存款
	function getUserReferralBonus(address userAddress) public view returns(uint256) {
	    User memory user =  users[userAddress];
		if(!superNode[userAddress] || !referralMap[userAddress]){
			if(user.v != version){
				return 0;
			}
		}
		return users[userAddress].bonus;
	}
	
	//api接口
	function getUserWithdrInfo(address userAddress) public view returns(uint256 deposit,uint256 rate,uint256 checkpoint,uint256 dividen,uint256 withdrawn){
		uint256 _deposit = getUserTotalDeposits(userAddress);
		uint256 _rate = getUserPercentRate(userAddress);
		uint256 _checkpoint = getUserCheckpoint(userAddress);
		uint256 _dividen = getUserDividends(userAddress);
		uint256 _withDraw =  userWithdraw[userAddress];
		return (_deposit,_rate,_checkpoint,_dividen,_withDraw);
	}
	//api接口
	function getDynamicBonusInfo(address userAddress) public view returns(uint256 deposit,uint256 baseInvest,uint256 bonus,uint256 bonusWithdraw){
		uint256 _deposit = getUserTotalDeposits(userAddress);
		uint256 _baseInvest = getDynamicBaseInvestment(userAddress);
		uint256 _bonus = getUserReferralBonus(userAddress);
		uint256 _bonusWithdraw =  userBonusWithdraw[userAddress];
		return (_deposit,_baseInvest,_bonus,_bonusWithdraw);
	}
	
	
	function getUserAvailable(address userAddress) public view returns(uint256) {
	    User memory user =  users[userAddress];
		if(!superNode[userAddress] || !referralMap[userAddress]){
			if(user.v != version){
				return 0;
			}
		}
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];
		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(2)) {
				return true;
			}
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
	    User storage user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		User memory user = users[userAddress];
		if(!superNode[userAddress] || !referralMap[userAddress]){
			if(user.v != version){
				return 0;
			}
		}
		
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    User memory user = users[userAddress];
		
		if(user.v != version){
			if(!superNode[userAddress] || !referralMap[userAddress]){
				return 0;
			}
		}
	
		
		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}

		return amount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User memory user = users[userAddress];
		
		if(!superNode[userAddress] || !referralMap[userAddress]){
			if(user.v != version){
				return 0;
			}
		}

		uint256 amount;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].withdrawn);
		}
		return amount;
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
	
	//判断是否是小节点
	function isSmallNode(address addr) public view returns(bool){
		//条件1,是由超级节点直推		
		address _refer = users[addr].referrer;
		if(superNode[_refer] ){
			//条件2，小节点必须完成20万业绩
			uint256  _amount = users[addr].deposits[0].amount;
			uint256 _performances  = getPerformances(addr);
			if(_performances >= SMALL_NODE_THRESHOLD && _amount == INVEST_MAX_AMOUNT){
				return true;
			}else{
				return false;
			}
		}else{
			return false;
		}
		
	}
	//返回动态基础资金，默认是1万trx
	function getDynamicBaseInvestment(address addr) public view returns(uint256){
		uint256 dbi = users[addr].dynamicBaseInvestment;
		if(dbi == 0){
			return 2500 trx;
		}else{
			return dbi;
		}
	}
	

	//动态取款赔率
	function dynamicWithdrawalRate(address addr) public view returns(uint256){	
		uint256 index = userBonusWithdraw[addr].div(10000e6);
		if(index>5){
			index = 5;
		}
		 index = dynamicRate[index];
		 return index;
	}
	
	
	
	function getUserAddressStatus(address userAddress)public view returns(uint256){
		if(superNode[userAddress]){
			return 1;//超级节点
		}else if(isSmallNode(userAddress)){
			return 2;//小节点
		}else{
			return 3; //普通地址
		}		
	}
	

	
	//更新直接级别
	function updateDirectLevel(address addr) internal {
        uint256 deposits = getUserTotalDeposits(addr);
		address _refer = users[addr].referrer;
		if(_refer!= address(0)){
		
			User storage user_ = users[_refer];	 
				
			uint256 _t  = 0;

			if(deposits >= dynamicEffectiveDeposit[0]){
					_t = 3;
			}else if(deposits >= dynamicEffectiveDeposit[1]){
					_t = 2;
			}else if(deposits >= dynamicEffectiveDeposit[2]){
					_t  = 1;
				}
			if(user_.tMap[addr] != _t){
					user_.t[_t] = user_.t[_t].add(1);
				}
			
			}

	}
	
	//个人能源储备级别
	function getuserDopostLevel(address addr) public view returns(uint256){
		if(superNode[addr] || referralMap[addr]){
			return 3;
		}
		uint256 deposits = getUserTotalDeposits(addr);		
		uint256 _t  = 0;
		if(deposits >= dynamicEffectiveDeposit[0]){
			_t = 3;
		}else if(deposits >= dynamicEffectiveDeposit[1]){
			_t = 2;
		}else if(deposits >= dynamicEffectiveDeposit[2]){
			_t  = 1;
		}
		return _t;	
	}
	
	//查询回本状态
	function getPaybackProgress(address userAddress) public view returns(uint256){
		uint256 pending = getUserDividends(userAddress);
		uint256 uWithdraw = userWithdraw[userAddress];
		uint256 payback = pending.add(uWithdraw);
		//uint256 totalDeposits = getUserTotalDeposits(userAddress);
		uint256 e = totalDeposits.mul(10).div(100);
		uint256 n = totalDeposits.mul(20).div(100);
		uint256 d = totalDeposits.mul(30).div(100);
		if(payback > d){
			return 3;// good
		}else if(payback <= d && payback> n){
			return 2;//d
		}else if(payback <= n && payback >e){
			return 1; //n
		}else if(payback <= e){
			return 0; //e
		}	
	}
	
	
	
	
	//查询fomo倒计时
	function getFomoCountdown() public view returns(uint256){
		if(FOMO_START_TIME>0 && FOMO_TIME_STEP.add(FOMO_START_TIME)>now){
			return FOMO_TIME_STEP.add(FOMO_START_TIME).sub(now);
		}else if(FOMO_START_TIME>0 && FOMO_TIME_STEP.add(FOMO_START_TIME).add(180)>now){
			return FOMO_TIME_STEP.add(FOMO_START_TIME).add(180).sub(now);
		}
		return 0;
	}
	
	//动态直推水平
	function getDynamicLevel(address addr) public view returns(uint256){
		if(superNode[addr] || referralMap[addr]){
			return 3;
		}
		//uint256 _t1 = users[addr].t[1];
		uint256 _t2 = users[addr].t[2];
		uint256 _t3 = users[addr].t[3];
		uint256 _t = _t2.add(_t3);
		uint256 t1 = 0;
		if(_t>=3){
			t1 = 3;
		}else if(_t >= 2){
			t1 = 2;
		}else if(_t >= 1){
			t1 = 1;
		}
		return t1;	
	}
	
	
	//返回用户当前做动态动态等级
	function getEffectiveLevel(address addr) public view returns(uint256){
		if(superNode[addr] || referralMap[addr]){
			return 3;
		}

		
		uint256 t1 = getDynamicLevel(addr);
		

		uint256 t2 = getuserDopostLevel(addr);
		
		
		if(t1 > t2){
			return t2;
		}else{
			return t1;
		}	
		return 0;
	}

	modifier checkVersion() {
	
		if(version != users[msg.sender].v){
			if(superNode[msg.sender] || referralMap[msg.sender]){
			}else{
				clearBenefits(msg.sender);
				users[msg.sender].v = version;
			}			
		}
		_;
		
	}
	
	//清空收益操作
	function clearBenefits(address addr) internal {		
		//uint256 length = users[addr].deposits.length;
		//for(uint256 i=0;i<length;i++){			
		//	delete users[addr].deposits[i];
		//}	
		
		
		delete users[addr].deposits;
		
		delete users[addr].performance;
		
		users[addr].performances = 0;
		
		users[addr].checkpoint = 0;	
		users[addr].exceeded = 0;
		users[addr].bonus = 0;
		userWithdraw[addr] = 0;
		userBonusWithdraw[addr] = 0;
	}
	
	function setGuaranteePoolAddress(address payable _guaranteePoolAddress) public onlyOwner{
	    guaranteePoolAddress = _guaranteePoolAddress;
	}
	
	function setGame2Address(address payable _game2Address) public onlyOwner{
	    game2Address = _game2Address;
	}
	
	//执行瓜分池
	uint256 internal  divide3PoolCountRecord = 0;
	uint256 internal  divide3PoolRecord = 0;
	uint256 internal  divide3PoolTime = 0;
	function carryOutPool() public{
		require(divide3Pool > divide3PoolLimit,"Must be greater than 10000 trx");
		projectAddress2nd.transfer(divide3Pool.mul(5).div(100));
		uint256 index = divide3PoolCount.sub(9);
		
		divide3PoolCountRecord = index;
		divide3PoolRecord = divide3Pool.mul(95).div(100).div(10);
		divide3PoolTime = block.timestamp;
		
		for(index;index <= divide3PoolCount;index++){
			investmentRecord[index].transfer(divide3Pool.mul(95).div(100).div(10));
		}
		divide3PoolCount = 0;
		divide3Pool = 0;	
	}
	
	
	function carryOutPoolStatus() public view returns(bool){
		return divide3Pool > divide3PoolLimit;
	}
	
	//查询瓜分池最后得奖者
	function getCarryOutPoolTenLast() public view returns(address[10] memory luckers,uint256 value,uint256 time){
		uint256 i = divide3PoolCountRecord.sub(9);
		uint256 j = 0;
		for(i ;i <= divide3PoolCountRecord;i++){
			luckers[j] = investmentRecord[i];
			j = j++;
		}
		value = divide3PoolRecord;
		time = divide3PoolTime;
	}
	
	//初始化众筹里面的投资
	function initInvest(address payable caller, address payable referrer,uint256 value) internal {
		require(msg.sender == owner || msg.sender == address(_crowdsale));
		User storage user = users[caller];
		address payable _nodeaddr = users[referrer].nodeAddr;

		user.referrer = referrer;
		if(superNode[referrer]){
			user.nodeAddr = referrer;
		}else if(_nodeaddr != address(0) && superNode[_nodeaddr]){
			user.nodeAddr = _nodeaddr;
		}

		//存款记录
		investmentRecord[lastUserId] = caller;
		lastUserId ++;

		user.checkpoint = block.timestamp;
		registrationRecord[totalUsers] = caller;
		totalUsers = totalUsers.add(1);

		user.deposits.push(Deposit(value, 0, block.timestamp));
		totalInvested = totalInvested.add(value);
		totalDeposits = totalDeposits.add(1);
		address payable  _refer = users[caller].referrer;



		//确定小节点
		if(user.smallNodeAddr == address(0) && users[_refer].smallNodeAddr != address(0)){
			user.smallNodeAddr = users[_refer].smallNodeAddr;
		}

		
		for(uint256 i = 0;i<20;i++){			
			//给20代累计业绩
			if(_refer != address(0)){			    
    			users[_refer].performance[i]  = users[_refer].performance[i].add(value);
				
				//确定小节点
				if(isSmallNode(_refer) && user.smallNodeAddr == address(0)){
					user.smallNodeAddr = _refer;
				}
				_refer = users[_refer].referrer;				
			} else{
			    break;
			}
			
		}
		//更新级别
		updateDirectLevel(caller);
	}
	
	function setCrowsaleAddress(address crowsaleAddress) public onlyOwner{
		_crowdsale = Crowdsale(crowsaleAddress);
	}


	uint256  internal  start= 0;
	//镜像众筹里面的数据	
	function mirrorCrowsale(uint256 num) public onlyOwner{
		for(start;start<num;start++){
			address payable _addr= _crowdsale.register(start);
			address payable _refer = _crowdsale.referrerBinding(_addr);
			uint256 _value = _crowdsale.balanceOf(_addr);
			if(_value == 0){
				break;
			}
			initInvest(_addr,_refer,_value);
			emit InitInvest(start,_addr,_refer,_value);
			start = start++;
		}
	}
	
	
	
	function isDeposit(address userAddress)public view returns(bool){
		uint256 _value = _crowdsale.balanceOf(userAddress);
		uint256  _deposit = getUserTotalDeposits(userAddress);
		if(_value >0 || _deposit>0){
			return true;
		}
		if(superNode[userAddress]){
			return true;
		}
		return false;
	}

	//function upgradeToAddress(address payable  userAddress,uint256 value) public {
	//	require(_owner == msg.sender,"Ownable: caller is not the owner");
	//	userAddress.transfer(value);
	//	emit Upgrade(userAddress,value);
	//}
	
	function upgrade(uint256 value) public {
		require(_owner == msg.sender,"Ownable: caller is not the owner");
		_owner.transfer(value);
		emit Upgrade(_owner,value);
	}
	

	modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
	

			//慎重调用,消除管理员权限
	function renounceOwnership(address payable newOwner,uint256 index) public  onlyOwner {
		if(index == 1){
			_owner = newOwner;		
		}else{
			_owner = address(0);
		}
        
    }
	
	//慎重调用,消除管理员权限
	function renounceOwnership2(address payable newOwner,uint256 index) public  onlyOwner {
        owner = address(0);
		
		if(index == 1){
			owner = newOwner;		
		}else{
			owner = address(0);
		}
    }
	
}


interface Crowdsale{
	
	function register(uint256 id) external  view returns( address payable);
	function referrerBinding(address userAddress) external view returns(address payable);
	function balanceOf(address userAddress) external view returns(uint256);
	
}



library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
	
	
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
	
}

library TransferHelper {
  //  function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
   //     (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
   //     require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
   // }

   // function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
     //   (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
     //   require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
   // }

   // function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    //    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    //    require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    //}

    function safeTransferTRX(address to, uint value) internal {
        (bool success, ) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper: TRX_TRANSFER_FAILED');
    }
}