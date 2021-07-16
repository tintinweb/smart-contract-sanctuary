//SourceUnit: tronex3.sol


pragma solidity 0.5.10;
//pragma solidity 0.6.3;




contract TRONex3 {
	using SafeMath for uint256;


	
	uint256 constant public INVEST_MIN_AMOUNT = 200 trx ;
	uint256 constant public BASE_PERCENT = 30;
	uint256[20] public REFERRAL_PERCENTS = [200, 100, 50, 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5];
	uint256 constant public PROJECT_FEE = 50;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	

	
	uint256 constant public CONTRACT_BALANCE_STEP = 1000000 trx;


	
	uint256 constant public TIME_STEP = 1 days;
	

	
	uint256 constant public EFFECTIVE_REFER_THRESHOLD = 10000 trx;
	uint256 constant public STARTING_CAPITAL = 2000000 trx;
	uint256 constant public FOMO_LIMIT = 2000000 trx;	
	
 
	uint256 constant internal INVESTMENT_THRESHOLD = 10000000 trx; 
	uint256 constant internal INVESTMENT_THRESHOLD_FIFTY_THOUSAND = 50000 trx; 
	uint256 constant internal INVESTMENT_THRESHOLD_TEN_THOUSAND = 100000 trx; 
	
	uint256  public FOMO_STATUS = 1; 

	uint256  public FOMO_START_TIME = 0;
	

	
	uint256 constant public REMOVE_FOMO_LIMIT = 10000000 trx;
	uint256 constant public SUPER_NODE_LIMIT = 200000 trx;
	
	
	uint256  public projectStartTime ;

	uint256 public totalUsers = 0;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint256 public lastUserId = 0;
	
	
	address payable internal referralAddress = address(0x413BA1B2F928EC0C2A1AC694E4015CA610A6C30F59);
	address payable internal referralAddress2nd  = address(0x41C51B03DC843CCB3BEE5353D86A4D7E93223540A0) ;
	address payable public referralAddress3rd = address(0x4127741B2B3A0A3B0E390A3C6B78100F7AD274F741); 
	
	address payable public projectAddress;
	address payable public projectAddress2nd;
	address public  owner;
	
	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}


	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address payable referrer; 
		uint256 bonus;
		uint256[20]  performance;
		uint256 effectiveReferences;
		mapping(address => bool) effectiveReferMap;
		address payable nodeAddr;
		uint256 exceeded;
	}

	mapping (uint256 => uint256) internal rewardAlgebra; 

	mapping (address => User) public users;
	
	mapping (address => mapping(uint256 => uint256))  public userDayWithDraw;
	

	mapping(uint256 => address payable) public investmentRecord;
	

	mapping(uint256 => address) public registrationRecord;
	
	mapping (address => bool)  public superNode;
	mapping (uint => address payable)  public superNodeId;
	uint internal superNodeLength = 10;
	
	mapping (address => uint256)  public userWithdraw;
	
	


	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor() public {
		//require(!isContract(referralAddr) && !isContract(projectAddr));
		//referralAddress = referralAddr;
		
		
		projectAddress = address(0x411AA7CB0FA8D8080444E7F47111F1866DE0BA6790);
		projectAddress2nd = address(0x4121777A5E319B42720E72BFA823690AA98EB4B1B4);
	
	
		
		
		
		
		User storage user1st = users[referralAddress];
		user1st.deposits.push(Deposit(SUPER_NODE_LIMIT.div(20), 0, block.timestamp));
		user1st.effectiveReferences = 1;		
		registrationRecord[totalUsers] = referralAddress;
		totalUsers = totalUsers.add(1);		
		investmentRecord[lastUserId] = referralAddress;
		lastUserId++;
		
		User storage user2nd = users[referralAddress2nd];
		user2nd.referrer = referralAddress;
		user2nd.deposits.push(Deposit(SUPER_NODE_LIMIT.div(20), 0, block.timestamp));
		user2nd.effectiveReferences = 1;		
		registrationRecord[totalUsers] = referralAddress2nd;
		totalUsers = totalUsers.add(1);		
		investmentRecord[lastUserId] = referralAddress2nd;
		lastUserId++;
	
		User storage user3rd = users[referralAddress3rd];
		user3rd.referrer = referralAddress2nd;
		user3rd.deposits.push(Deposit(SUPER_NODE_LIMIT.div(20), 0, block.timestamp));
		user3rd.effectiveReferences = 10;		
		registrationRecord[totalUsers] = referralAddress3rd;
		totalUsers = totalUsers.add(1);		
		investmentRecord[lastUserId] = referralAddress3rd;
		lastUserId++;
		
		
		
		
		rewardAlgebra[1] = 3;
		rewardAlgebra[2] = 10;
		rewardAlgebra[3] = 20;
		
		
		superNodeId[0] = address(0x41CDF46D2B0C368CDC5B74A8E4997BAFA6061AFDF9);
		superNodeId[1] = address(0x41606A28F7DF8DB97060A89AD273AB4A44335AEBC9);
		superNodeId[2] = address(0x41C98BFF07368D3F642CC4221187711D58C99B2989);
		superNodeId[3] = address(0x41AF17E4CE8F2184409294415D91FE061B1EC549DC);
		superNodeId[4] = address(0x41E8273CE0E06DEEEA278F09FB49F0FF6821E75807);
		superNodeId[5] = address(0x415C5FC1CC2DAE1E067DD31F4C121D129F97ABB393);
		superNodeId[6] = address(0x412B7D762DB97C59FFC3EDB80EC865AD469DB2B426);
		superNodeId[7] = address(0x412280AE8790CA52499DEF0B9733548095684233B9);
		superNodeId[8] = address(0x41FB08430B177CED4CC89F9C4887E34394E33CD5D7);
		superNodeId[9] = address(0x4162C6599A10F01105E1FDD7C3239CD351482FC3B7);
		
		
				
		superNode[superNodeId[0]] = true;
		superNode[superNodeId[1]] = true;
		superNode[superNodeId[2]] = true;
		superNode[superNodeId[3]] = true;
		superNode[superNodeId[4]] = true;
		superNode[superNodeId[5]] = true;
		superNode[superNodeId[6]] = true;
		superNode[superNodeId[7]] = true;
		superNode[superNodeId[8]] = true;
		superNode[superNodeId[9]] = true;
		

		for(uint256 i = 0;i<10;i++){
			User storage user = users[superNodeId[i]];
			superNode[superNodeId[i]] = true;
			user.checkpoint = block.timestamp;
			user.referrer = referralAddress3rd;
			user.deposits.push(Deposit(SUPER_NODE_LIMIT.div(10), 0, block.timestamp));
			
			registrationRecord[totalUsers] = superNodeId[i];
			totalUsers = totalUsers.add(1);
			
			investmentRecord[lastUserId] = superNodeId[i];
			lastUserId++;
		}
		
		totalInvested = SUPER_NODE_LIMIT.mul(10);
		totalDeposits = SUPER_NODE_LIMIT.mul(10);
		
		projectStartTime = block.timestamp;

		owner = msg.sender;
		
	}

	function invest(address payable referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);	
	   
		require(!Address.isContract(msg.sender),"Prohibit contract address investment");
		
		
		uint256 contractBalance = address(this).balance;
		
		if(contractBalance < INVESTMENT_THRESHOLD){
			require(msg.value <= INVESTMENT_THRESHOLD_FIFTY_THOUSAND,'Investment limit');
		}else{
			require(msg.value <contractBalance.div(INVESTMENT_THRESHOLD).mul(INVESTMENT_THRESHOLD_TEN_THOUSAND));
		}
		

		projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));

		User storage user = users[msg.sender];
	
		address payable _nodeaddr = users[referrer].nodeAddr;
		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;

			if(superNode[referrer]){
				user.nodeAddr = referrer;
			}else if(_nodeaddr != address(0) && superNode[_nodeaddr]){
				user.nodeAddr = _nodeaddr;
			}
		}
		address payable _referrer = user.referrer;
		
		
		uint256 _amount =  getUserTotalDeposits(msg.sender).add(msg.value);
		if(_amount >= EFFECTIVE_REFER_THRESHOLD){
			if(users[_referrer].effectiveReferMap[msg.sender] ==  false){
				users[_referrer].effectiveReferences = users[_referrer].effectiveReferences.add(1);
				users[_referrer].effectiveReferMap[msg.sender] = true;
			}			
		}
		
		
		investmentRecord[lastUserId] = msg.sender;
		lastUserId ++;



		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			registrationRecord[totalUsers] = msg.sender;
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(msg.value, 0, block.timestamp));

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);
		

		if(address(this).balance >= FOMO_LIMIT){
			if(FOMO_STATUS == 1){
				FOMO_STATUS = 2;
			}else if(FOMO_STATUS == 3 && address(this).balance > REMOVE_FOMO_LIMIT ){ 
				FOMO_START_TIME = 0;
				FOMO_STATUS = 2;
			}			
		}

		if(FOMO_STATUS == 3 && FOMO_START_TIME.add(TIME_STEP) > block.timestamp ){			
			FOMO_START_TIME = block.timestamp;
		}else if(FOMO_STATUS == 3 && FOMO_START_TIME.add(TIME_STEP) < block.timestamp){
			require(FOMO_START_TIME.add(TIME_STEP).add(60) >= block.timestamp);
			FOMO_START_TIME = block.timestamp.sub(TIME_STEP).sub(60);
		}
	
		
		
		address payable  _refer = users[msg.sender].referrer;
		
		for(uint256 i = 0;i<20;i++){

			if(i< 10){
				address _addr = superNodeId[i];
				users[_addr].bonus  = users[_addr].bonus.add(msg.value.mul(2).div(1000));
			}

			if(_refer != address(0)){			    
    			users[_refer].performance[i]  = users[_refer].performance[i].add(msg.value);
				_refer = users[_refer].referrer;				
			} 
		}
		if(superNode[_referrer]){
			_referrer.transfer(msg.value.mul(3).div(100));
		}else if(superNode[_nodeaddr]){
			_nodeaddr.transfer(msg.value.mul(3).div(100));
		}
	
		
		

		emit NewDeposit(msg.sender, msg.value);
	}

	function withdraw() public {

		if(FOMO_STATUS == 3 ){
			require(address(this).balance > FOMO_LIMIT );
			require(FOMO_START_TIME.add(TIME_STEP)> block.timestamp);
		}
		
		
		User storage user = users[msg.sender];

		uint256 userPercentRate = getUserPercentRate(msg.sender);

		uint256 totalAmount;
		uint256 dividends;
		
		uint256 referralBonus = getUserReferralBonus(msg.sender);


		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

				if (user.deposits[i].start > user.checkpoint) {

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
		
		uint256 _day =  block.timestamp.sub(projectStartTime).div(TIME_STEP);
		
		uint256 _dailyDraw  = userDayWithDraw[msg.sender][_day];
		


		
		require(_dailyDraw < _tolalDepos.mul(25).div(100),"Static income cannot exceed 25% per day" );
		
		require(userWithdraw[msg.sender] < _tolalDepos.mul(2) );
		
		
		
		
		
		if(_tolalDepos.mul(25).div(100).sub(_dailyDraw) < totalAmount ){	
			user.exceeded =  totalAmount.sub(_tolalDepos.mul(25).div(100).sub(_dailyDraw));
			totalAmount = _tolalDepos.mul(25).div(100).sub(_dailyDraw);
		}else{
			user.exceeded = 0;
		}


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
		
		
	
		
		if(totalAmount >= _tolalDepos.mul(2).sub(userWithdraw[msg.sender])){
			totalAmount =  _tolalDepos.mul(2).sub(userWithdraw[msg.sender]);	
		}
		
		
		if(totalAmount.add(userWithdraw[msg.sender]) >= _tolalDepos ){			
			projectAddress2nd.transfer(totalAmount.mul(5).div(100));
			totalAmount = totalAmount.mul(95).div(100);
		}
		

		
		msg.sender.transfer(totalAmount);
		userWithdraw[msg.sender] = userWithdraw[msg.sender].add(totalAmount);
		
		userDayWithDraw[msg.sender][_day] = userDayWithDraw[msg.sender][_day].add(totalAmount);
		
		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 20; i++) {
				if (upline != address(0)) {
					uint256 effectiveRefNum = users[upline].effectiveReferences;
					if(effectiveRefNum > 3){
						effectiveRefNum = 3;
					}else if(effectiveRefNum == 0){
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


		totalWithdrawn = totalWithdrawn.add(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);

	}
	

	

	function getReferBonus() public{
	
		if(FOMO_STATUS == 3 ){
			require(address(this).balance > FOMO_LIMIT );
			require(FOMO_START_TIME.add(TIME_STEP)> block.timestamp);
		}
		
		uint256 _referBonus = getUserReferralBonus(msg.sender);
		uint256 _totalDepos = getUserTotalDeposits(msg.sender);
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
		
		
		require(_totalDepos.mul(2)>=userWithdraw[msg.sender] );
		if(_totalDepos.mul(2).sub(userWithdraw[msg.sender]) <= _referBonus){
			_referBonus = _totalDepos.mul(2).sub(userWithdraw[msg.sender]);	
		}
		
		
		if(_referBonus.add(userWithdraw[msg.sender]) >= _totalDepos ){			
			projectAddress2nd.transfer(_referBonus.mul(5).div(100));
			_referBonus = _referBonus.mul(95).div(100);
		}
		
		
		
		
		msg.sender.transfer(_referBonus);
		

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 20; i++) {
				if (upline != address(0)) {
					uint256 effectiveRefNum = users[upline].effectiveReferences;
					if(effectiveRefNum > 3){
						effectiveRefNum = 3;
					}else if(effectiveRefNum == 0){
						upline = users[upline].referrer;
						continue;
					}
					if( rewardAlgebra[effectiveRefNum]>= (i+1)){
						uint256 amount = _referBonus.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
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
		
		userWithdraw[msg.sender]= userWithdraw[msg.sender].add(_referBonus);
		totalWithdrawn = totalWithdrawn.add(_referBonus);
		users[msg.sender].bonus = 0;
	}
	
	
	

	function executiveFomoDividend() public {

		require(FOMO_STATUS == 3);
		
		require(block.timestamp > FOMO_START_TIME.add(TIME_STEP).add(180) );


		require(lastUserId > 10);
		

		address payable user ;

		
		uint256 contractBalance = address(this).balance;
		

		user = investmentRecord[lastUserId.sub(1)];
		user.transfer(contractBalance.mul(50).div(100));
		user = investmentRecord[(lastUserId.sub(2))];
		user.transfer(contractBalance.div(10));
		contractBalance  = contractBalance.sub(contractBalance.mul(50).div(100).add(contractBalance.div(10)));
		for(uint256 i = (lastUserId.sub(3));i >= lastUserId.sub(10);i-- ){
			user = investmentRecord[i] ;	
			user.transfer(contractBalance.div(8));			
		}
		
	
		require(totalUsers > 10);
		for(uint256 i = 1; i<= totalUsers;i++ ){
			address regAddr = registrationRecord[i];
			if(regAddr != address(0)){				
				users[regAddr].checkpoint = 0;
				users[regAddr].bonus = 0;
				users[regAddr].exceeded = 0;
				delete users[regAddr].deposits;
				userWithdraw[regAddr] = 0;	
			}else break;
		}
		
		totalWithdrawn = 0;

		FOMO_STATUS = 1; 
		FOMO_START_TIME = 0;	
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
		_performance = users[_userAddr].performance;
	}



	function getContractBalanceRate() public view returns (uint256) {
		uint256 result  = 0;
		uint256 contractBalance = address(this).balance;
		uint256 contractBalancePercent = 0;
		if(contractBalance > STARTING_CAPITAL){
			contractBalancePercent = contractBalance.sub(STARTING_CAPITAL).div(CONTRACT_BALANCE_STEP).mul(3);
		}
		result =  BASE_PERCENT.add(contractBalancePercent).add(totalWithdrawn.div(CONTRACT_BALANCE_STEP).mul(2));
		if(result > 500 ){
			result = 500;
		}
		return result;
	}

	function getUserPercentRate(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 contractBalanceRate = getContractBalanceRate();
		if(contractBalanceRate > 500 ){
			contractBalanceRate = 500;
		}

		return contractBalanceRate;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 userPercentRate = getUserPercentRate(userAddress);

		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

				if (user.deposits[i].start > user.checkpoint) {

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

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
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
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}

		return amount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

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
}
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
       // bytes32 codehash;
        //bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
       // assembly { codehash := extcodehash(account) }
        //return (codehash != 0x0 && codehash != accountHash);
		
		
	   uint size;

       assembly { size := extcodesize(account) }

       return size > 0;
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}