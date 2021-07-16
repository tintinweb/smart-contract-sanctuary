//SourceUnit: TronUnity.sol

pragma solidity ^0.5.10;

contract TronUnity {
	using SafeMath for uint256;
	address payable public owner;
	address payable public owner2;
	address payable public developer;
	address payable public programmer;

	uint256 constant public INVEST_MIN_AMOUNT = 100 trx;
	uint256 public BASE_PERCENT = 100;
	uint256[3] public REFERRAL_PERCENTS = [80,15,5];
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
// 	uint256 OneMillion = 1000000;
	
	uint256 public totalreinvested;
	
	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}
	
	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256 bonus;
		uint256 level1;
		uint256 level2;
		uint256 level3;
		uint256 reinvestwallet;
		uint256 showBonus;
	}

	mapping (address => User) public users;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	
	
	constructor(address payable _owner1,address payable _owner2,address payable _developer,address payable _programmer) public {
		owner=_owner1;
		owner2=_owner2;
		developer=_developer;
		programmer=_programmer;

	}

	function invest(address referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);
		
		owner.transfer(msg.value.mul(40).div(PERCENTS_DIVIDER));
	   	owner2.transfer(msg.value.mul(40).div(PERCENTS_DIVIDER));
	   	developer.transfer(msg.value.mul(10).div(PERCENTS_DIVIDER));
	   	programmer.transfer(msg.value.mul(10).div(PERCENTS_DIVIDER));
	
		User storage user = users[msg.sender];
		
		if(msg.sender == owner){
		    user.referrer = address(0);
		}else if (user.referrer == address(0)) {
		    
			if ((users[referrer].deposits.length == 0 || referrer == msg.sender) && msg.sender != owner) {
				referrer = owner;
			}

			user.referrer = referrer;

            address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    if (i == 0) {
                        users[upline].level1 = users[upline].level1.add(1);
                    } else if (i == 1) {
                        users[upline].level2 = users[upline].level2.add(1);
                    } else if (i == 2) {
                        users[upline].level3 = users[upline].level3.add(1);
                    }
                     
					upline = users[upline].referrer;
				} else break;
            }
		}

		if (user.referrer != address(0)) {

			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}

		}
		
        if (user.deposits.length == 0) {
			totalUsers = totalUsers.add(1);
		}
		user.deposits.push(Deposit(msg.value, 0, block.timestamp));
	    user.checkpoint = block.timestamp;
		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, msg.value);
	
	}

	function withdraw() public {
		User storage user = users[msg.sender];

        uint256 base = setPercent(msg.sender);
		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(200).div(100)) {


					dividends = (user.deposits[i].amount.mul(base).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
                   user.deposits[i].start=now;
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(200).div(100)) {
					dividends = (user.deposits[i].amount.mul(200).div(100)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
			
			
		}

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
		if(totalAmount > 100e9){
		    totalAmount = 100e9;
		}
		user.checkpoint=block.timestamp;
		msg.sender.transfer(totalAmount);
		totalWithdrawn = totalWithdrawn.add(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);
		
		if (user.referrer != address(0)) {

			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = totalAmount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}

		}
		

	}
	


	
	function Reinvest(uint256 _value) internal {
	    uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			_value = _value.add(referralBonus);
			users[msg.sender].showBonus=users[msg.sender].showBonus.add(referralBonus);
			users[msg.sender].bonus = 0;
		}
		
		owner.transfer(msg.value.mul(40).div(PERCENTS_DIVIDER));
	   	owner2.transfer(msg.value.mul(40).div(PERCENTS_DIVIDER));
	   	developer.transfer(msg.value.mul(10).div(PERCENTS_DIVIDER));
	   	programmer.transfer(msg.value.mul(10).div(PERCENTS_DIVIDER));
		
		User storage user = users[msg.sender];
		user.deposits.push(Deposit(_value, 0, block.timestamp));
		user.checkpoint = block.timestamp;
		user.reinvestwallet=user.reinvestwallet.add(_value);
		totalInvested = totalInvested.add(_value);
		totalDeposits = totalDeposits.add(1);
		totalreinvested = totalreinvested.add(_value);
		emit NewDeposit(msg.sender, _value);
	}
	function ReinvestSTake()public returns(bool){ 
	    
        User storage user = users[msg.sender];
        uint256 base = setPercent(msg.sender);
		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(200).div(100)) {


					dividends = (user.deposits[i].amount.mul(base).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
                   
			    user.deposits[i].start=now;
			
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(200).div(100)) {
					dividends = (user.deposits[i].amount.mul(200).div(100)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
			
		}


		uint256 contractBalance = address(this).balance;
		
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
		totalWithdrawn = totalWithdrawn.add(totalAmount);
		
        Reinvest(totalAmount);

    return true;
    
    }
    
	function getContractBalance() public view returns (uint256) {
	    
		return address(this).balance;
		
	}

	function getUserDividendsWithdrawable(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		uint256 base = setPercent(msg.sender);
		uint256 totalDividends;
		uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(200).div(100)) {
			    
					dividends = (user.deposits[i].amount.mul(base).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(200).div(100)) {
					dividends = (user.deposits[i].amount.mul(200).div(100)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);

			}

		}

		return (totalDividends);
	}
	
	function getUserDividendsReinvestable(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		uint256 base = setPercent(msg.sender);
		uint256 totalDividends;
		uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(200).div(100)) {
			    
					dividends = (user.deposits[i].amount.mul(base).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(200).div(100)) {
					dividends = (user.deposits[i].amount.mul(200).div(100)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);

			}

		}
		

		return (totalDividends.add(getUserReferralBonus(userAddress)));
	}
	
	function GetBonus(address userAddress) public view returns(uint256){
	    User storage user = users[userAddress];
	    uint256 bonus;
	    bonus = block.timestamp.sub(user.checkpoint).div(TIME_STEP);
	    if(bonus <= 20) return bonus.mul(5);
	    else return 100;
	}
	
	function setPercent(address userAddress) public view returns(uint256){
	    return BASE_PERCENT.add(GetBonus(userAddress)); 
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

	function isActive(address userAddress,uint256 index) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[index].withdrawn < user.deposits[index].amount.mul(200).div(100)) {
				return true;
			}
			else{
			    return false;
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

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].level1, users[userAddress].level2, users[userAddress].level3);
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