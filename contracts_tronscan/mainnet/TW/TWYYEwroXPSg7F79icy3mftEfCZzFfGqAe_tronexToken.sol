//SourceUnit: tronexMax_release.sol

pragma solidity 0.5.12;

contract Creator {
    address payable public creator;

    constructor() public {
        creator = msg.sender;
    }


    modifier creatorOnly {
        assert(msg.sender == creator);
        _;
    }
}


contract tronexToken is Creator{
    using SafeMath for uint256;

    uint256 constant public INVEST_MIN_AMOUNT = 100 trx;
    uint256 constant public CONTRACT_BALANCE_STEP = 1000000 trx; 
    uint256 constant public TIME_STEP = 1 days;               

    uint256 constant public BASE_PERCENT = 10;
    uint256 constant public MAX_PERCENT = 100;
    uint256 public REFERRAL_PERCENTS = 150;


    uint256 constant public PROJECT_FEE = 50;
    uint256 constant public PERCENTS_DIVIDER = 1000;
	
	uint256[]  public admin_fee = [300, 200, 100, 50, 50, 30,30,30,30,30,10,10,10,10,10,10,10,10,10,10];

    uint256 private totalUsers;       
    uint256 private totalInvested;    
    uint256 private totalWithdrawn;   
    uint256 private totalDeposits;    
	
	uint256 public lastInvestTime;    
	bool private isStop;              
	uint256 public spanLastTime = 12 hours;  
	
	struct LastUser{
		address user;
		uint256 investTime; 
	}
	LastUser[10] public lastUserArr;   
	
	uint256 lastUserIndex;
	

    address payable public projectAddress;

    struct Deposit {  
        uint256 amount;  
        uint256 withdrawn; 
        uint256 start; 
        uint256 drawntime; 
		uint256 contact_amount;  
    }
	struct Admin_info{
		uint256 amount;
		uint256 drawntime;
	}

    struct User {  
		uint256 allAmount; 
		uint256 bonus;     
		uint256 bonus_with_draw;  
		uint256 admin_bonus;      
		uint256 admin_with_draw;  
        address referrer;  
		uint256 down_number;
        Deposit[] deposits;   
		Admin_info[20] admin_infos; 
    }
	
    mapping(address => User) public users;   

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 t);
    event RefBonus(address indexed referrer, address indexed referral, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);

    constructor() public {
		lastInvestTime = block.timestamp;
    }

    modifier IsInitialized {
        require(projectAddress != address(0), "not Initialized");
        _;
    }
 
    function initialize(address payable projectAddr) public payable creatorOnly {

        require(projectAddress == address(0)&& projectAddr!= address(0), "initialize only would call once");
        require(!isContract(projectAddr)&&(tx.origin == msg.sender));
        projectAddress = projectAddr;
    }
	
	
	function addLastUser(address user) internal {
		
		bool flag;
		uint256 i = 0;
		lastInvestTime = block.timestamp;   
		for(i = 0; i < 10; i++){
			if(lastUserArr[i].investTime == 0){
				break;
			}
			if(lastUserArr[i].user == user){
				flag = true;
				break;
			}
		}
		if(flag == true){ 
			lastUserArr[i].investTime = block.timestamp;
			return;
		}
		
		if(lastUserIndex == 10){
			lastUserIndex = 0;
		}
		lastUserArr[lastUserIndex].user = user;
		lastUserArr[lastUserIndex].investTime = block.timestamp;
		lastUserIndex = lastUserIndex.add(1);
		return;
	}

	function checkLastInvestTime() internal {
		require(isStop == false, "already stop");
		if(block.timestamp.sub(lastInvestTime) <= spanLastTime){
			return;
		}
		
		uint256 num;
		uint256 i;
		for(i = 0; i < 10; i++){
			if(lastUserArr[i].investTime == 0){
				break;
			}
		}
		num = i;
		
		uint total = address(this).balance;
		
		if(num == 0 || total == 0){
			isStop = true;
			return;
		}
		
		uint perAmount = total.div(num);
		if(perAmount != 0){
			for(uint256 j = 0; j < num; j++){
				address(uint160(lastUserArr[j].user)).transfer(perAmount);
			}
		}
		isStop = true;
		return;
	}
	
	function getLastUser() view public returns(uint256 lastTime, address[10] memory userArr, uint256[10] memory timeArr){
		address[10] memory a;
		uint256[10] memory b;
		for(uint i = 0; i < 10; i++){
			a[i] = lastUserArr[i].user;
			b[i] = lastUserArr[i].investTime;
		}
		return (lastInvestTime, a, b);
	}

	
    function invest(address referrer) public payable IsInitialized {  
		checkLastInvestTime();
		if(isStop == true){
			return;
		}
        require(!isContract(referrer) && !isContract(msg.sender)&&(tx.origin == msg.sender)); 
        address upline = referrer;  
        require(msg.value >= INVEST_MIN_AMOUNT, "less than limit");  
        User storage user = users[msg.sender];    

        if (referrer != projectAddress) {   
            if (user.referrer == address(0)) {  
                if (upline == address(0) || users[upline].deposits.length == 0 || referrer == msg.sender) { 
                    //require(false, "check failed");
					upline = projectAddress;
                }
            }
        }
        emit NewDeposit(msg.sender, msg.value); 

        uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);  
        projectAddress.transfer(fee);  
		


        emit FeePayed(msg.sender, fee);  
		
		

        if (user.referrer == address(0)) { 
            user.referrer = upline;  
			users[user.referrer].down_number = users[user.referrer].down_number.add(1);
        }
		

	
		user.allAmount = user.allAmount.add(msg.value);

        upline = user.referrer;
		
		for(uint256 i = 0; i < 20; i++){ 
			if(upline != address(0)){
				if(users[upline].admin_infos[i].amount == 0){
					users[upline].admin_infos[i].drawntime = block.timestamp;
				}
				users[upline].admin_infos[i].amount = users[upline].admin_infos[i].amount.add(msg.value);
				if(upline == projectAddress){
					break;
				}
			}
			else{
				break;
			}
			upline = users[upline].referrer;
		}
		
		
		upline = user.referrer;
		if(upline != address(0)){
			if(msg.sender != creator){
				uint256 amount = msg.value.mul(REFERRAL_PERCENTS).div(PERCENTS_DIVIDER);
				users[upline].bonus = users[upline].bonus.add(amount);
				emit RefBonus(upline, msg.sender, amount);
			}
			else{ 
				users[msg.sender].bonus = users[msg.sender].bonus.add(msg.value.mul(2));
			}
		}

        if (user.deposits.length == 0) {    
            totalUsers = totalUsers.add(1);  
            emit Newbie(msg.sender);         
        }
        user.deposits.push(Deposit(msg.value, 0, block.timestamp, block.timestamp, address(this).balance));  
        totalInvested = totalInvested.add(msg.value);   
        totalDeposits = totalDeposits.add(1);           

		addLastUser(msg.sender); 
    }
	
	
	function withdraw_static() public IsInitialized { 
		checkLastInvestTime();
		if(isStop == true){
			return;
		}

        require(!isContract(msg.sender)&&(tx.origin == msg.sender));   

        User storage user = users[msg.sender];  

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {  
            Deposit memory temp = user.deposits[i];
            if (temp.withdrawn < temp.amount.mul(2)) { 
                uint256 userPercentRate = getUserPercentRate(msg.sender, temp.drawntime, temp.contact_amount); 
                dividends = (temp.amount.mul(userPercentRate).div(PERCENTS_DIVIDER)) 
                .mul(block.timestamp.sub(temp.drawntime)) 
                .div(TIME_STEP);  
                if (temp.withdrawn.add(dividends) > temp.amount.mul(2)) {  
                    dividends = (temp.amount.mul(2)).sub(temp.withdrawn);
                }
                totalAmount = totalAmount.add(dividends);   
                /// changing of storage data
                user.deposits[i].withdrawn = temp.withdrawn.add(dividends);
                user.deposits[i].drawntime = block.timestamp;
            }
        }
        require(totalAmount > 0, "User has no dividends");
		
		address upline = user.referrer;
		
		
		for(uint256 i = 0; i < 20; i++){ 
			if(upline != address(0)){
				if(users[upline].admin_infos[i].amount > 0){
					
					uint256 timeMultiplier = (block.timestamp.sub(users[upline].admin_infos[i].drawntime)).div(TIME_STEP); 
					uint256 percent = BASE_PERCENT.add(timeMultiplier.min(40)); 
					uint a = users[upline].admin_infos[i].amount.mul(percent).mul(admin_fee[i]);
					uint b = block.timestamp.sub(users[upline].admin_infos[i].drawntime);
					users[upline].admin_bonus = users[upline].admin_bonus.add(a.mul(b).div(TIME_STEP).div(PERCENTS_DIVIDER).div(PERCENTS_DIVIDER));
					
					if(users[upline].admin_infos[i].amount > totalAmount){
						users[upline].admin_infos[i].amount = users[upline].admin_infos[i].amount.sub(totalAmount);
					}
					else{
						users[upline].admin_infos[i].amount = 0;
					}
					users[upline].admin_infos[i].drawntime = block.timestamp;
				}
				if(upline == projectAddress){
					break;
				}
			}
			else{
				break;
			}
			upline = users[upline].referrer;
		}
        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        msg.sender.transfer(totalAmount);
        totalWithdrawn = totalWithdrawn.add(totalAmount);
        emit Withdrawn(msg.sender, totalAmount, 0);
    }
	
	
	function withdraw_out() public IsInitialized { 
		checkLastInvestTime();
		if(isStop == true){
			return;
		}

        require(!isContract(msg.sender)&&(tx.origin == msg.sender));  

        User storage user = users[msg.sender];  

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {  
            Deposit memory temp = user.deposits[i];
            if (temp.withdrawn < temp.amount.mul(2)) { 
                uint256 userPercentRate = getUserPercentRate(msg.sender, temp.drawntime, temp.contact_amount); 
                dividends = (temp.amount.mul(userPercentRate).div(PERCENTS_DIVIDER)) 
                .mul(block.timestamp.sub(temp.drawntime)) 
                .div(TIME_STEP);  
                if (temp.withdrawn.add(dividends) > temp.amount.mul(2)) {  
                    dividends = (temp.amount.mul(2)).sub(temp.withdrawn);
					
					totalAmount = totalAmount.add(dividends);
					user.deposits[i].withdrawn = temp.withdrawn.add(dividends);
					user.deposits[i].drawntime = block.timestamp;
                }                
            }
        }
        require(totalAmount > 0, "User has no dividends");
		
		address upline = user.referrer;
		
		
		for(uint256 i = 0; i < 20; i++){ 
			if(upline != address(0)){
				if(users[upline].admin_infos[i].amount > 0){
					
					uint256 timeMultiplier = (block.timestamp.sub(users[upline].admin_infos[i].drawntime)).div(TIME_STEP); 
					uint256 percent = BASE_PERCENT.add(timeMultiplier.min(40)); 
					uint a = users[upline].admin_infos[i].amount.mul(percent).mul(admin_fee[i]);
					uint b = block.timestamp.sub(users[upline].admin_infos[i].drawntime);
					users[upline].admin_bonus = users[upline].admin_bonus.add(a.mul(b).div(TIME_STEP).div(PERCENTS_DIVIDER).div(PERCENTS_DIVIDER));
					
					if(users[upline].admin_infos[i].amount > totalAmount){
						users[upline].admin_infos[i].amount = users[upline].admin_infos[i].amount.sub(totalAmount);
					}
					else{
						users[upline].admin_infos[i].amount = 0;
					}
					users[upline].admin_infos[i].drawntime = block.timestamp;
				}
				if(upline == projectAddress){
					break;
				}
			}
			else{
				break;
			}
			upline = users[upline].referrer;
		}
        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        msg.sender.transfer(totalAmount);
        totalWithdrawn = totalWithdrawn.add(totalAmount);
        emit Withdrawn(msg.sender, totalAmount, 2);
    }
	
	
    function withdraw_dynamic() public IsInitialized { 
		checkLastInvestTime();
		if(isStop == true){
			return;
		}
        require(!isContract(msg.sender)&&(tx.origin == msg.sender));  

        User storage user = users[msg.sender];  
		
		require(user.allAmount.mul(2) > user.bonus_with_draw.add(user.admin_with_draw), "already tow times");
		
        uint256 totalAmount;
		uint256 user_all_withdraw = user.bonus_with_draw.add(user.admin_with_draw);
		
		
		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if(referralBonus > 0){
			
			if(user_all_withdraw.add(referralBonus) > user.allAmount.mul(2)){
				referralBonus = user.allAmount.mul(2).sub(user_all_withdraw);
			}
			user.bonus_with_draw = user.bonus_with_draw.add(referralBonus);
			totalAmount = referralBonus;
			if(referralBonus == user.bonus){
				user.bonus = 0;
			}
			else{
				user.bonus = user.bonus.sub(referralBonus);
			}
		}
		
		
		uint256 adminBonus = 0;
		for(uint256 i = 0; i < user.admin_infos.length; i++){
			if(user.admin_infos[i].amount != 0){
				uint256 timeMultiplier = (block.timestamp.sub(user.admin_infos[i].drawntime)).div(TIME_STEP); 
				uint256 percent = BASE_PERCENT.add(timeMultiplier.min(40)); 
				uint a =  user.admin_infos[i].amount.mul(percent).mul(admin_fee[i]);
				uint b = block.timestamp.sub(user.admin_infos[i].drawntime);
				uint c = a.mul(b).div(TIME_STEP).div(PERCENTS_DIVIDER).div(PERCENTS_DIVIDER);
				adminBonus = adminBonus.add(c);
				user.admin_infos[i].drawntime = block.timestamp;
			}
		}
		adminBonus = adminBonus.add(user.admin_bonus);
		user.admin_bonus = 0;
		
		if(adminBonus > 0){
			if(user_all_withdraw.add(totalAmount).add(adminBonus) > user.allAmount.mul(2)){
				uint256 temp = user.allAmount.mul(2).sub(user_all_withdraw.add(totalAmount));
				user.admin_bonus = adminBonus.sub(temp);
				adminBonus = temp;
			}
			user.admin_with_draw = user.admin_with_draw.add(adminBonus);
			totalAmount = totalAmount.add(adminBonus);
		}
		
		require(totalAmount > 0, "User has no dividends");
		
		
		uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        msg.sender.transfer(totalAmount);
        totalWithdrawn = totalWithdrawn.add(totalAmount);
        emit Withdrawn(msg.sender, totalAmount, 1);
	}
		

    function getInfo(address userAddress) public view returns (uint256[20] memory) {
        uint256[20] memory info;
        uint i = 0;
		
		uint256 referralBonus = getUserReferralBonus(userAddress);
		
		uint256 adminBonus = getUserAdminBonus(userAddress);
		
		uint256 bonus_with_draw = users[userAddress].bonus_with_draw;
		
		uint256 admin_with_draw = users[userAddress].admin_with_draw;
		
		uint256 total;
		if(bonus_with_draw.add(admin_with_draw).add(referralBonus.add(adminBonus)) > users[userAddress].allAmount.mul(2)){
		    uint a = users[userAddress].allAmount;
			total = a.mul(2).sub(bonus_with_draw).sub(admin_with_draw);
		}
		else{
			total = referralBonus.add(adminBonus);
		}
		
        /* 0 */info[i++] = address(this).balance;  
        /* 1 */info[i++] = getUserPercentMaxRate(userAddress); 
        /* 2 */info[i++] = getContractBalanceMaxRate(userAddress);   
        /* 3 */info[i++] = getUserDividends(userAddress); 
        /* 4 */info[i++] = users[userAddress].down_number; 
        /* 5 */info[i++] = getUserTotalDeposits(userAddress); 
        /* 6 */info[i++] = getUserTotalWithdrawn(userAddress); 
        /* 7 */info[i++] = users[userAddress].deposits.length; 
        /* 8 */info[i++] = totalUsers; 
        /* 9 */info[i++] = totalInvested; 
        /* 10 */info[i++] = totalWithdrawn; 
        /* 11 */info[i++] = totalDeposits;  
        /* 12 */info[i++] = getUserReferralBonus(userAddress);  
		/* 13 */info[i++] = getUserAdminBonus(userAddress);     
		/* 14 */info[i++] = users[userAddress].bonus_with_draw; 
		/* 15 */info[i++] = users[userAddress].admin_with_draw; 
		/* 16 */info[i++] = total;                              
		/* 17 */info[i++] = getUserDividendsOut(userAddress);   

        return info;
    }
	
	function getAdminInfos(address userAddress) public view returns(uint256[5] memory){
		User memory user = users[userAddress];
		uint256[5] memory info;
		uint i = 0;
		info[i++] = user.admin_infos[0].amount;
		info[i++] = user.admin_infos[1].amount;
		info[i++] = user.admin_infos[2].amount;
		info[i++] = user.admin_infos[3].amount;
		info[i++] = user.admin_infos[4].amount;
		return info;
	}
	
	function getUserAdminBonus(address userAddress) public view returns(uint256){ 
		uint256 adminBonus = 0;
		User memory user = users[userAddress];
		for(uint256 i = 0; i < user.admin_infos.length; i++){
			if(user.admin_infos[i].amount != 0){
				uint256 timeMultiplier = (block.timestamp.sub(user.admin_infos[i].drawntime)).div(TIME_STEP); 
				uint256 percent = BASE_PERCENT.add(timeMultiplier.min(40)); 
				uint a = user.admin_infos[i].amount.mul(percent).mul(admin_fee[i]);
				uint b = block.timestamp.sub(user.admin_infos[i].drawntime);
				uint c = a.mul(b).div(TIME_STEP).div(PERCENTS_DIVIDER).div(PERCENTS_DIVIDER);
				adminBonus = adminBonus.add(c);
			}
		}
		adminBonus = adminBonus.add(user.admin_bonus);
		return adminBonus;
	}
		
	
    function getContractBalance() internal view returns (uint256) {
        return address(this).balance;
    }
	
    function getContractBalanceRate(uint256 base_amount) public view returns (uint256) { 
        uint256 contractBalance = address(this).balance;  
		if(contractBalance > base_amount){
			contractBalance = contractBalance.sub(base_amount);
		}
		else{
			contractBalance = 0;
		}
        uint256 contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP);  
        contractBalancePercent = contractBalancePercent.min(MAX_PERCENT);  
        return BASE_PERCENT.add(contractBalancePercent);  
    }
	
    function getUserPercentRate(address userAddress, uint256 time, uint256 base_amount) internal view returns (uint256) {
        uint256 contractBalanceRate = getContractBalanceRate(base_amount); 
        if (isActive(userAddress)) { 
            uint256 timeMultiplier = (block.timestamp.sub(time)).div(TIME_STEP); 
            return contractBalanceRate.add(timeMultiplier.min(40));  
        } else { 
            return contractBalanceRate;  
        }
    }
	
	function getContractBalanceMaxRate(address userAddress) public view returns (uint256){ 
		User memory user = users[userAddress]; 
		uint256 base_amount = uint256(-1);
        for (uint256 i = 0; i < user.deposits.length; i++) { 
            Deposit memory temp = user.deposits[i];  
			if (temp.withdrawn < temp.amount.mul(2)) {  
                base_amount = base_amount.min(temp.contact_amount);
            }
        }
		return getContractBalanceRate(base_amount);  
	}
	

    function getUserPercentMaxRate(address userAddress) internal view returns (uint256) {
        User memory user = users[userAddress]; 
        uint256 time = block.timestamp;  
		uint256 base_amount = uint256(-1);
        for (uint256 i = 0; i < user.deposits.length; i++) { 
            Deposit memory temp = user.deposits[i];  
            if (temp.withdrawn < temp.amount.mul(2)) {  
                time = time.min(temp.drawntime);  
                base_amount = base_amount.min(temp.contact_amount);
            }
        }
        return getUserPercentRate(userAddress, time, base_amount);  
    }
	
    function getUserDividends(address userAddress) internal view returns (uint256) {
        User memory user = users[userAddress]; 
        uint256 totalDividends = 0;
        uint256 dividends = 0;

        for (uint256 i = 0; i < user.deposits.length; i++) {  
            Deposit memory temp = user.deposits[i];  

            if (temp.withdrawn < temp.amount.mul(2)) {  
                uint256 userPercentRate = getUserPercentRate(msg.sender, temp.drawntime, temp.contact_amount); 
                dividends = (temp.amount.mul(userPercentRate).div(PERCENTS_DIVIDER)) 
                .mul(block.timestamp.sub(temp.drawntime))   
                .div(TIME_STEP);
                if (temp.withdrawn.add(dividends) > temp.amount.mul(2)) {
                    dividends = (temp.amount.mul(2)).sub(temp.withdrawn);
                }
                totalDividends = totalDividends.add(dividends);
                
            }
        }

        return totalDividends;
    }
	
	
    function getUserDividendsOut(address userAddress) internal view returns (uint256) {
        User memory user = users[userAddress]; 
        uint256 totalDividends = 0;
        uint256 dividends = 0;

        for (uint256 i = 0; i < user.deposits.length; i++) {  
            Deposit memory temp = user.deposits[i];  

            if (temp.withdrawn < temp.amount.mul(2)) {  
                uint256 userPercentRate = getUserPercentRate(msg.sender, temp.drawntime, temp.contact_amount); 
                dividends = (temp.amount.mul(userPercentRate).div(PERCENTS_DIVIDER)) 
                .mul(block.timestamp.sub(temp.drawntime))   
                .div(TIME_STEP);
                if (temp.withdrawn.add(dividends) > temp.amount.mul(2)) {
                    dividends = (temp.amount.mul(2)).sub(temp.withdrawn);
					totalDividends = totalDividends.add(dividends);
                }
                
               
            }
        }

        return totalDividends;
    }

	
    function getUserReferralBonus(address userAddress) internal view returns (uint256) {
        return users[userAddress].bonus;
    }
	// 
    function getUserAvailable(address userAddress) internal view returns (uint256) {
        return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
    }
	
    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        if (user.deposits.length > 0) {
			for(uint256 i = 0; i < user.deposits.length; i++){
				if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {
					return true;
				}
			}
        }
        return false;
    }

	
    function getUserDepositInfo(address userAddress, uint256 index) public view returns (uint256, uint256, uint256) {
        User storage user = users[userAddress];

        return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
    }
	
    function getUserAmountOfDeposits(address userAddress) public view returns (uint256) {
        return users[userAddress].deposits.length;
    }
	
    function getUserTotalDeposits(address userAddress) internal view returns (uint256) {
		return users[userAddress].allAmount;
    }
		
	function getUserTotalWithdrawn(address userAddress) internal view returns (uint256) {
        User storage user = users[userAddress];
        uint256 amount;
        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].withdrawn);
        }
        return amount;
    }
	
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {size := extcodesize(addr)}
        return size > 0;
    }

}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
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

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);
}