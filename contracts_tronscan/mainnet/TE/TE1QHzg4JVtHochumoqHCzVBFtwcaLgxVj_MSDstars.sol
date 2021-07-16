//SourceUnit: msddstar (2).sol

pragma solidity ^0.5.10;

contract MSDstars {
	using SafeMath for uint256;
	address payable public owner;
	uint256 constant public INVEST_MIN_AMOUNT = 200 trx;
	uint256[20] public REFERRAL_PERCENTS = [50,30,20,10,5,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	
	uint256 public totalreinvested;
	
	struct Deposit {
	    bool isActive;
		uint256 amount;
		uint256 start;
		uint8 pkg;
	}
	
	struct User {
		address payable referrer;
        uint256 checkpint;
		uint256 withdrawn;
		uint256 bonus;
		uint256 sixtotwnety;
	}
	mapping(address => uint256[5]) public reinvestwallets;
    mapping(address => uint256[20]) public levels;
	mapping (address => User) public users;
	mapping (address => mapping(uint8 => Deposit)) public userPkg;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	
	
	constructor(address payable _owner) public {
		owner=_owner;
	}

	function invest(address payable referrer,uint8 pkg) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);
		require(pkg > 0 && pkg < 6,"incorrect pkg");
		require(userPkg[msg.sender][pkg].isActive == false,"already in progress");
		User storage user = users[msg.sender];
		
		uint256 amount = msg.value;
		if(reinvestwallets[msg.sender][pkg-1] > 0  ){
		amount = amount.add(reinvestwallets[msg.sender][pkg-1]);
		reinvestwallets[msg.sender][pkg-1] = 0 ;
        }
		owner.transfer(amount.mul(70).div(PERCENTS_DIVIDER));
		
		uint8 _pkg;
		if(pkg == 1) _pkg = 110;
		else if(pkg == 2) _pkg = 120;
		else if(pkg == 3) _pkg = 130;
		else if(pkg == 4) _pkg = 150;
		else _pkg = 200;

		
		
		
		if (user.referrer == address(0)) {
			totalUsers = totalUsers.add(1);
			user.checkpint=block.timestamp;
		}
		
		userPkg[msg.sender][pkg] = Deposit({
            isActive: true,
            amount: amount,
            start: block.timestamp,
            pkg: _pkg
        });
		
		if(msg.sender == owner){
		    user.referrer = address(0);
		}else if (user.referrer == address(0)) {
		    
			if (users[referrer].referrer == address(0) || referrer == msg.sender) {
				referrer = owner;
			}

			user.referrer = referrer;

            address upline = user.referrer;
			for (uint256 i = 0; i < 20; i++) {
                if (upline != address(0)) {
                    levels[upline][i] = levels[upline][i].add(1);
                     if(i >=5 && levels[upline][0]>=10)
                     {
                     users[upline].sixtotwnety = users[upline].sixtotwnety.add(1);
                     }
					upline = users[upline].referrer;
				} else break;
            }
		}

		if (user.referrer != address(0)) {

			address payable upline = user.referrer;
			uint256 _amount;
			for (uint256 i = 0; i < REFERRAL_PERCENTS.length ; i++) {
				if (upline != address(0)) {
					_amount = amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					if(upline == owner) upline.transfer(_amount);
					else if(i<5) upline.transfer(_amount);
					else if(i >= 5 && levels[upline][0] >= 10){
					    upline.transfer(_amount);
					}
					users[upline].bonus = users[upline].bonus.add(_amount);
					emit RefBonus(upline, msg.sender, i, _amount);
					upline = users[upline].referrer;
				} else break;
			}

		}
		
		totalInvested = totalInvested.add(amount);
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, amount);
	
	}

	function withdraw(uint8 pkg) public {
        
        User storage user = users[msg.sender];
		Deposit storage deposit = userPkg[msg.sender][pkg];
		require(deposit.isActive == true,"you don't have any active deposit");
		require(pkg > 0 && pkg < 6,"incorrect pkg");
		
        if(pkg == 1) require(block.timestamp > deposit.start + (10 days),"you can not withdraw amount before time");
		else if(pkg == 2) require(block.timestamp > deposit.start + (15 days),"you can not withdraw amount before time");
		else if(pkg == 3) require(block.timestamp > deposit.start + (20 days),"you can not withdraw amount before time");  
		else if(pkg == 4) require(block.timestamp > deposit.start + (30 days),"you can not withdraw amount before time");
		else require(block.timestamp > deposit.start + (50 days),"you can not withdraw amount before time");


	    uint256 totalAmount = deposit.amount.mul(deposit.pkg).div(100);
	
		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
		deposit.isActive = false;
		msg.sender.transfer(totalAmount.mul(75).div(100));
		reinvestwallets[msg.sender][pkg-1] = reinvestwallets[msg.sender][pkg-1].add(totalAmount.mul(25).div(100));
		user.withdrawn = user.withdrawn.add(totalAmount);
		totalWithdrawn = totalWithdrawn.add(totalAmount);
		
		if(pkg == 1) deposit.start = 0;
		else if(pkg == 2) deposit.start =  0;
		else if(pkg == 3) deposit.start = 0;  
		else if(pkg == 4) deposit.start = 0;
		else deposit.start = 0;
		emit Withdrawn(msg.sender, totalAmount);
		

	}
	

	function Reinvest(uint256 value, uint8 pkg) internal {
	
		owner.transfer(msg.value.mul(70).div(PERCENTS_DIVIDER));
		
        uint8 _pkg;
		if(pkg == 1) _pkg = 110;
		else if(pkg == 2) _pkg = 120;
		else if(pkg == 3) _pkg = 130;
		else if(pkg == 4) _pkg = 150;
		else _pkg = 200;

		
		userPkg[msg.sender][pkg] = Deposit({
            isActive: true,
            amount: value,
            start: block.timestamp,
            pkg: _pkg
        });

// 		user.deposits.push(Deposit(_value, 0, block.timestamp));
		totalInvested = totalInvested.add(value);
		totalDeposits = totalDeposits.add(1);
		totalreinvested = totalreinvested.add(value);
		emit NewDeposit(msg.sender, value);
	}
	function ReinvestSTake(uint8 pkg)public returns(bool){ 
	    
	   // User storage user = users[msg.sender];
		Deposit storage deposit = userPkg[msg.sender][pkg];
		require(deposit.isActive == true,"you don't have any active deposit");
		require(pkg > 0 && pkg < 6,"incorrect pkg");
		
        if(pkg == 1) require(block.timestamp > deposit.start + (10 days),"you can not withdraw amount before time");
		else if(pkg == 2) require(block.timestamp > deposit.start + (15 days),"you can not withdraw amount before time");
		else if(pkg == 3) require(block.timestamp > deposit.start + (20 days),"you can not withdraw amount before time");  
		else if(pkg == 4) require(block.timestamp > deposit.start + (30 days),"you can not withdraw amount before time");
		else require(block.timestamp > deposit.start + (50 days),"you can not withdraw amount before time");
	    


	    uint256 totalAmount = deposit.amount.mul(deposit.pkg).div(100);

		uint256 contractBalance = address(this).balance;
		
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
		
		deposit.isActive == false;
		totalWithdrawn = totalWithdrawn.add(totalAmount);
		
        Reinvest(totalAmount,pkg);

    return true;
    
    }
    
	function getContractBalance() public view returns (uint256) {
	    
		return address(this).balance;
		
	}
	
	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}
	

	function getUserDownlineCount(address userAddress) public view returns (uint256[20] memory arr) {
	         for(uint256 i = 0 ; i<20;i++){
	         
	         arr[i] = levels[userAddress][i] ;
	         
	         }
	         return arr;
	}


	function getUserTotalDeposits(address userAddress) public view returns(uint256) {

		uint256 amount;

		for (uint8 i = 1; i < 6; i++) {
		    if(userPkg[userAddress][i].isActive == true)
			    amount = amount.add(userPkg[userAddress][i].amount);
		}

		return amount;
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    
    
    
    
	function register(address payable referrer) public  {
		
		User storage user = users[msg.sender];
		
		require(user.checkpint<1," your are already registered");
		
		user.checkpint=block.timestamp;
		
		if (user.referrer == address(0)) {
			totalUsers = totalUsers.add(1);
		}
		
		if(msg.sender == owner){
		    user.referrer = address(0);
		}else if (user.referrer == address(0)) {
		    
			if (users[referrer].referrer == address(0) || referrer == msg.sender) {
				referrer = owner;
			}

			user.referrer = referrer;

            address upline = user.referrer;
			for (uint256 i = 0; i < 20; i++) {
                if (upline != address(0)) {
                    
                        levels[upline][i] = levels[upline][i].add(1);
                        if(i >=5 && levels[upline][0]>=10)
                     {
                     users[upline].sixtotwnety = users[upline].sixtotwnety.add(1);
                     }
                     
					upline = users[upline].referrer;
				} else break;
            }
		}


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