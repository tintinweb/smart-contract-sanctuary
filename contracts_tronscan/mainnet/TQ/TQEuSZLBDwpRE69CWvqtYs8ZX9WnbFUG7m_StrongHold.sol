//SourceUnit: Address.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.8;
library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

}

//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.8;
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }

}

//SourceUnit: StrongHold.sol

// SPDX-License-Identifier: MIT
import "./SafeMath.sol";
import "./Address.sol";

pragma solidity 0.5.8;

contract StrongHold{
    using SafeMath for uint;
    using Address for address;
    
    uint constant public INVEST_MIN_AMOUNT =250 trx; 
    
	uint constant public BASE_PERCENT = 100;
	uint constant public ACTIVATE_PLAN = 200;
	
	uint constant public REINVESTMENT_PERCENT = 1100;
	uint constant public REFERRAL_PERCENTS = 70;
	uint constant public REFERRAL_BONUS_PERCENTS = 300;
	uint constant public REFERRAL_HOLD_PERCENTS = 500;
	
    uint constant public MARKETING_FEE = 20;
	
	uint constant public OWNER_FEE = 350;
	uint constant public PROJECT_FEE = 350;
	uint constant public DEVELOPMENT_FEE = 300;
	
	uint constant public PERCENTS_DIVIDER = 1000;
	
	
	uint constant public MAX_MATRIX = 5;
	
	uint constant public TIME_CYCLE = 20  days;
	uint constant public TIME_STEP = 1 days; 
	
	uint public totalUsers;
	uint public totalInvested;
	uint public totalReferralHold;
	uint public totalWithdrawn;
	uint public totalDeposits;
	uint public time_start;

	address payable public owner;
	address payable public marketingAddress;
	address payable public projectAddress;
	address payable public developmentAddress;


    struct Deposit {
		uint[4] amount;
		uint currentPay;
		uint lastAmount;
		uint nextPayment;
		uint withdrawn;
		uint start;
		uint cycle;
		bool active;
		uint bonusCheckpoint;
		bool[3] cyclePaid;
		bool[3] reinvesmentPaid;
	}
	
	
	struct User {		
		Deposit deposits;
		address referrer;
		uint256[] matrixBonus;
		uint referrerCount;
		uint checkpoint;
		uint totalAmount;
		uint totalWithdrawn;
		bool registered;
	}

	mapping (address => User) internal users;

	event NewUser(address user);
	event NewDeposit(address indexed user, uint amount);
	event Reinvestment(address indexed user, uint amount);
	event Withdrawn(address indexed user, uint amount);
	event WithdrawnOnlyBonus(address indexed user, uint amount);
	event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
	event FeePayed(address indexed user, uint totalAmount);
    
	constructor( address payable owner_,
	address payable marketingAddress_,
	address payable projectAddress_,
	address payable developmentAddress_ ) public {
		marketingAddress =marketingAddress_;
		owner =owner_;
		projectAddress =projectAddress_;
		developmentAddress =developmentAddress_;
		time_start=block.timestamp;
	}
	
	modifier start{
	    require(block.timestamp.sub(time_start) > 6 days,"coming soon");
	    _;
	}
    
    function invest(address referrer) external start payable{
        _deposits(msg.value, referrer);
    }
    
    function _deposits(uint depAmount, address referrer) internal {
        require(!isActive(msg.sender),"User is active");
        require(users[msg.sender].deposits.amount[0] == 0, "User plan started");
        require(depAmount >= INVEST_MIN_AMOUNT, "Minimum deposit amount 250 trx");
        
        uint marketingFee = depAmount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        marketingAddress.transfer(marketingFee);
		emit FeePayed(msg.sender, marketingFee);
        
		User storage user = users[msg.sender];

        if (user.referrer == address(0) && users[referrer].deposits.active && referrer != msg.sender) 
            user.referrer = referrer;
	
		if (user.referrer != address(0)) 
		{
			address upline = user.referrer;
    		uint amount = depAmount.mul(REFERRAL_PERCENTS).div(PERCENTS_DIVIDER);
		    users[upline].matrixBonus.push(amount);
		    users[upline].referrerCount = users[upline].referrerCount.add(1);
		    emit RefBonus(upline, msg.sender,0,amount);
		}
        
		if (user.deposits.amount[0] == 0 && !user.registered) 
		{
		    user.registered=true;			
			totalUsers = totalUsers.add(1);
			emit NewUser(msg.sender);
		}

        user.deposits.amount[0] =depAmount;
        user.deposits.lastAmount=depAmount;
        user.deposits.nextPayment = calculateReinvesment(depAmount);
        user.deposits.start=block.timestamp;
		user.totalAmount  =user.totalAmount.add(depAmount);
		user.checkpoint = block.timestamp;				        
		totalInvested = totalInvested.add(depAmount);
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, depAmount);
    }
    
    function withdrawOnlyBonus() external payable {
        require(isActive(msg.sender),"user dont active");
        require(users[msg.sender].deposits.reinvesmentPaid[1],"Error");
        require(block.timestamp.sub(users[msg.sender].deposits.bonusCheckpoint) > TIME_CYCLE,"cycle fail");
        
        uint amout = handlerReferralBonus(msg.sender);
        users[msg.sender].totalWithdrawn =users[msg.sender].totalWithdrawn.add(amout);
        totalWithdrawn =totalWithdrawn.add(amout);
        if(address(this).balance < amout)
        {
            amout = address(this).balance;
            totalReferralHold =0;
        }
        msg.sender.transfer(amout);
        emit WithdrawnOnlyBonus(msg.sender,amout);
    }
    
    function withdraw(User storage user) internal {
        uint dividends =user.deposits.currentPay;
        for(uint i = 0; i <user.deposits.cycle; i++){
            if(!user.deposits.cyclePaid[i])
                user.deposits.cyclePaid[i] = true;
        }
        delete user.deposits.currentPay;
        
        if(address(this).balance < dividends){
            if(address(this).balance < totalReferralHold)
                dividends = 0;
            else
             dividends = address(this).balance.sub(totalReferralHold);
        }
        
        if(address(this).balance < totalReferralHold)
            dividends = 0;
        
        if(user.deposits.reinvesmentPaid[2]){
            dividends =dividends.add(handlerReferralBonus(msg.sender));
            delete user.deposits;
        }
        
        if(address(this).balance < dividends){
            dividends = address(this).balance;
            totalReferralHold=0;
        }
        user.deposits.withdrawn =user.deposits.withdrawn.add(dividends);
        user.totalWithdrawn =user.totalWithdrawn.add(dividends);
        msg.sender.transfer(dividends);
        totalWithdrawn =totalWithdrawn.add(dividends);
        emit Withdrawn(msg.sender, dividends);
    }
    
    function payReinvesment () external payable{
        require(isActive(msg.sender),"user dont active");
        User storage user = users[msg.sender];
        require(!user.deposits.reinvesmentPaid[2],"reinvestment paid");
        require(block.timestamp.sub(user.checkpoint) > TIME_CYCLE,"cycle fail");
        require(msg.value == user.deposits.nextPayment,"Reinvesment  110%");
        
        uint marketingFee = user.deposits.nextPayment.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        marketingAddress.transfer(marketingFee);
		emit FeePayed(msg.sender, marketingFee);
        
        user.deposits.reinvesmentPaid[user.deposits.cycle]=true;
        if(user.deposits.reinvesmentPaid[1] && user.deposits.bonusCheckpoint == 0 )
            user.deposits.bonusCheckpoint=block.timestamp;
        user.deposits.currentPay = user.deposits.currentPay.add(user.deposits.lastAmount.mul(2));
        user.deposits.cycle =user.deposits.cycle.add(1);
        user.deposits.amount[user.deposits.cycle]=msg.value;
        user.deposits.nextPayment = calculateReinvesment(msg.value);
        user.deposits.lastAmount =msg.value;
        
        user.totalAmount  =user.totalAmount.add(msg.value);
        user.checkpoint =block.timestamp;
        totalInvested = totalInvested.add(msg.value);
        emit NewDeposit(msg.sender, msg.value);
        withdraw(user);
    }
    
    function activateUser() external payable {
        require(!isActive(msg.sender),"User is active");
        require(users[msg.sender].deposits.amount[0] != 0,"user did not deposit");
        uint amount =users[msg.sender].deposits.amount[0].mul(ACTIVATE_PLAN).div(PERCENTS_DIVIDER);
        require(amount==msg.value,"deposit 20% of the investment");
        
        uint referralHold = amount.mul(REFERRAL_HOLD_PERCENTS).div(PERCENTS_DIVIDER);
        totalReferralHold=totalReferralHold.add(referralHold);
        // pay fee
        owner.transfer(referralHold
        .mul(OWNER_FEE)
        .div(PERCENTS_DIVIDER));
        
        projectAddress.transfer(referralHold
        .mul(PROJECT_FEE)
        .div(PERCENTS_DIVIDER));
        
	    developmentAddress.transfer(referralHold
	    .mul(DEVELOPMENT_FEE)
	    .div(PERCENTS_DIVIDER));
	    
	    emit FeePayed(msg.sender, referralHold);
	    
	    User storage user = users[msg.sender];
        
        user.deposits.active=true;
        user.deposits.start=block.timestamp;
        user.checkpoint=block.timestamp;
    }
    
    function calculateUserCurrentDividens(address userAddress) external view returns(uint){
        User memory user = users[userAddress];
        
        if(!user.deposits.active )
            return 0;
        if(user.deposits.cycle > 2 )
        return user.deposits.currentPay;
        
        uint lastAmount;
        
        if(user.deposits.cycle > 0){
            for(uint i=0; i < 3;i++){
                if(!user.deposits.reinvesmentPaid[i])
                    break;
                if(user.deposits.cyclePaid[i])
                continue;
                if(i==0 && !user.deposits.cyclePaid[i]){
                    lastAmount =lastAmount.add(user.deposits.amount[i].mul(2));
                    continue;
                }
                lastAmount =lastAmount.add(user.deposits.amount[i].mul(2));
            }
        }
        
        uint amount = user.deposits.lastAmount.mul(BASE_PERCENT)
					.div(PERCENTS_DIVIDER)
                    .mul( block.timestamp.sub( user.checkpoint ) )
					.div(TIME_STEP);
        
        
        if(amount < user.deposits.lastAmount.mul(2))
            return  lastAmount.add(amount);
        else
            return lastAmount.add(user.deposits.lastAmount.mul(2));
    }
    
    function isActive(address userAddress) public view returns (bool) {		
		return users[userAddress].deposits.active;
	}
	function isUser(address userAddress) public view returns (bool) {		
		return users[userAddress].deposits.amount[0] > 0;
	}
    
    function calculateReinvesment(uint value) internal pure returns(uint){
        uint amoutn = value.mul(REINVESTMENT_PERCENT).div(PERCENTS_DIVIDER);
        return amoutn;
    }
    
    function nextUserReinvesmentAmount(address userAddress) external view returns(uint){
        if(users[userAddress].deposits.cycle  <= 2)		
		return users[userAddress].deposits.nextPayment;
    }
    
    function getReferralCount(address userAddress ) external view returns(uint){
        return  users[userAddress].referrerCount.sub(this.getUserMatrixsPaid(userAddress)); 
    }
    
    function getUserMatrixsCreated(address userAddress ) external view returns(uint){
     return   users[userAddress].referrerCount.div(MAX_MATRIX);
    }
    
    function getUserMatrixsPaid(address userAddress ) external view returns(uint){
        User memory user = users[userAddress];
		uint counter = user.referrerCount.div(MAX_MATRIX);
		if(counter < 1)
		return 0;
		uint n;
		for (uint i=0; i < counter.mul(MAX_MATRIX);i++){
		    if(user.matrixBonus[i] != 0)
		    break;
		    else
		    n++;
		}
        return  n.div(MAX_MATRIX);
    }
    
    
    function getUserTotalDeposits(address userAddress) external view returns(uint256) {	    
		return users[userAddress].totalAmount;
	}
	
	function getUserTotalWithdrawn(address userAddress) external view returns(uint256) {	    
		return users[userAddress].totalWithdrawn;
	}
	
	function getBonusData()  external view returns(
	    uint256 matrixCreated_,
	    uint256 matrixPayed_,
	    uint256 referralBonus_
	    ){
	    referralBonus_=this.getUserReferralBonus(msg.sender);
	    matrixCreated_=this.getUserMatrixsCreated(msg.sender);
	    matrixPayed_ = this.getUserMatrixsPaid(msg.sender);
	}

	function getMainInfo() external view returns(
	    uint256 balace_,
	    uint256 totalReferralHold_,
	    bool isUser_,
	    bool isActive_
	    ){
	    balace_= this.getContractBalance();
	    totalReferralHold_= totalReferralHold;
	    isUser_=isUser(msg.sender);
	    isActive_=isActive(msg.sender);
	}
	
	
	function getUserDepositInfo(address userAddress) external view returns(
	    uint256 currentPay_, 
	    uint256 lastAmount_,
	    uint256 nextPayment_,
	    uint256 reinvestment_,
	    uint256 cycle_,
	    uint256 withdrawn_, 
	    uint256 start_,
	    uint256 initAmount_,
	    uint256 state_,
	    address upLine_,
	    bool active_) {
	    User memory user = users[userAddress];
	    upLine_ =user.referrer;
		currentPay_ = this.calculateUserCurrentDividens(userAddress);
		lastAmount_ = user.deposits.lastAmount;
		nextPayment_ = lastAmount_.mul(2);
		if(user.deposits.cycle  <= 2)
		reinvestment_ = user.deposits.nextPayment;
		cycle_ = user.deposits.cycle;
		withdrawn_ = user.deposits.withdrawn;
		initAmount_=user.deposits.amount[0];
		start_ = user.deposits.start;
		active_ =user.deposits.active;
		state_ = block.timestamp.sub(user.checkpoint);
	}
	
	function getUserDeposiState(address userAddress) external view returns(
		uint256[4] memory amount_, 
		bool[3] memory cyclePaid_,
		bool[3] memory reinvesmentPaid_) {
	    User memory user = users[userAddress];		
		amount_ = user.deposits.amount;
		cyclePaid_ = user.deposits.cyclePaid;
		reinvesmentPaid_ =user.deposits.reinvesmentPaid;
	}
	
	
	
	function getUserReferrer(address userAddress) external view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserReferralBonus(address userAddress) external view returns(uint256) {
		User memory user = users[userAddress];
		uint counter = user.referrerCount.div(MAX_MATRIX);
		if(counter < 1)
		return 0;
		
		uint amount;
		for (uint i=0; i < counter.mul(MAX_MATRIX); i++){
		    uint amount_ =user.matrixBonus[i];
		    if(amount_ == 0)
		    continue;
		    amount = amount.add(amount_);
		}
		if(amount!=0){
		uint referralBonus =amount.mul(REFERRAL_BONUS_PERCENTS).div(PERCENTS_DIVIDER);  //add bonus 30%
		amount = amount.add(referralBonus);
		}
		return amount;
	}
	function handlerReferralBonus(address userAddress) internal returns(uint256) {
		User storage user = users[userAddress];
		uint counter = user.referrerCount.div(MAX_MATRIX);
		if(counter < 1)
		return 0;
		
		uint amount;
		for (uint i=0; i < counter.mul(MAX_MATRIX);i++){
		    uint amount_ =user.matrixBonus[i];
		    if(amount_ == 0)
		    continue;
		    amount = amount.add(amount_);
		    delete user.matrixBonus[i]; //clear bonus
		}
		
		uint referralBonus =amount.mul(REFERRAL_BONUS_PERCENTS).div(PERCENTS_DIVIDER);  //add add bonus 30%
		amount = amount.add(referralBonus);
		
		if(amount != 0){
		    if(totalReferralHold >= amount)
		        totalReferralHold =totalReferralHold.sub(amount);
		    else{
		        amount = totalReferralHold;
		        totalReferralHold=0;
		    }   
		
		}
		return amount;
	}
	
	function getUserCheckpoint(address userAddress) external view returns(uint256) {
		return users[userAddress].checkpoint;
	}
	
	function getContractBalance() external view returns (uint) {
		return address(this).balance;
	}
    
    function() external payable {        
    }
    
}