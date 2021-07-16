//SourceUnit: TronAngelCoin.sol

pragma solidity ^0.5.10;

contract Owned {
    modifier onlyOwner() {
        require(msg.sender==owner);
        _;
    }
    
    address payable owner;
    address payable newOwner;
    function changeOwner(address payable _newOwner) public onlyOwner {
        require(_newOwner!=address(0));
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        if (msg.sender==newOwner) {
            owner = newOwner;
        }
    }
}

    interface TAC {
    function balanceOf(address _owner) view external  returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value)  external  returns (bool success);
    function approve(address _spender, uint256 _value)  external returns (bool success);
    }

contract TronAngelCoin { 
	using SafeMath for uint256;
	uint256 constant public INVEST_MIN_AMOUNT = 100e6;
	uint256  public BASE_PERCENT = 80;
	uint256[3] public REFERRAL_PERCENTS = [80, 50, 20];
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	address payable public owner;
	address payable public poolAddress;
	TAC public tokenInstance;
	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}
	struct User {
		Deposit[] deposits;
		uint256 a;
	}
	struct Ref{
	    address referrer;
		uint256 bonus;
		uint256 level1;
		uint256 level2;
		uint256 level3;
		uint256 ref1;
		uint256 ref2;
		uint256 ref3;
		uint256 withdrawRef;
	}
	uint256 public totalTokens;
	mapping(address =>Ref)public refusers;
	mapping (address => User) public users;
	mapping(address =>uint256)public reward;
	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	constructor(address payable _owner,address _tokenInstance,address payable _poolAddress) public {
	    tokenInstance=TAC(_tokenInstance);
		owner = _owner;
		poolAddress=_poolAddress;
	}
	function invest(address referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);
		poolAddress.transfer(msg.value.mul(5).div(100));
		User storage user = users[msg.sender];
		
		
		if (refusers[msg.sender].referrer == address(0)) {
			if ((users[referrer].deposits.length == 0 || referrer == msg.sender) && msg.sender != owner) {
				referrer = owner;
			}

			Ref storage refuser = refusers[msg.sender];
			refuser.referrer = referrer;
		

            address upline = refuser.referrer;
			for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    if (i == 0) {
                        refusers[upline].ref1 = refusers[upline].ref1.add(1);
                    } else if (i == 1) {
                        refusers[upline].ref2 = refusers[upline].ref2.add(1);
                    } else if (i == 2) {
                        refusers[upline].ref3 = refusers[upline].ref3.add(1);
                    }
					upline = refusers[upline].referrer;
				} else break;
            }
		}


		
		if (user.deposits.length == 0) {
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}
		
		user.deposits.push(Deposit(msg.value, 0, block.timestamp));
		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);
		emit NewDeposit(msg.sender, msg.value);

	}

	function withdraw() public {
		User storage user = users[msg.sender];
		uint256 totalAmount;
		uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(10000))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
						user.deposits[i].start=block.timestamp;
				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);
		}
		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			refusers[msg.sender].withdrawRef = refusers[msg.sender].withdrawRef.add(referralBonus);
			refusers[msg.sender].bonus = 0;
		}
		
		totalAmount=totalAmount.div(100);
		if (refusers[msg.sender].referrer != address(0)) {
			address upline = refusers[msg.sender].referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = totalAmount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					refusers[upline].bonus = refusers[upline].bonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					if (i == 0) {
                        refusers[upline].level1 = refusers[upline].level1.add(amount);
                    } else if (i == 1) {
                        refusers[upline].level2 = refusers[upline].level2.add(amount);
                    } else if (i == 2) {
                        refusers[upline].level3 = refusers[upline].level3.add(amount);
                    }
					upline = refusers[upline].referrer;
				} else break;
			}

		}

        tokenInstance.transfer(msg.sender,totalAmount);
		totalWithdrawn = totalWithdrawn.add(totalAmount);
		totalTokens=totalTokens.add(totalAmount);
		 mining();
		emit Withdrawn(msg.sender, totalAmount);
	}
	function mining()internal {
	    if(totalTokens>1000000e4){
	        BASE_PERCENT=BASE_PERCENT.div(2);
	        totalTokens=0;
	        if(BASE_PERCENT==0){
	            BASE_PERCENT=1;
	        }
	    }
	}

    function unStakeAndExit()public returns(bool){
        uint256 totalAmount;
         totalAmount=getUserTotalDeposits(msg.sender);
         uint256 a=totalAmount.mul(10).div(100);
         msg.sender.transfer(totalAmount.sub(a));
         withdraw();
         delete users[msg.sender];
         return true;
    }  
    
    
    function unstake()public returns(bool){
        reward[msg.sender]=getUserDividends(msg.sender);
        uint256 totalAmount=getUserTotalDeposits(msg.sender);
        uint256 a=totalAmount.mul(10).div(100);
        msg.sender.transfer(totalAmount.sub(a));
        delete users[msg.sender];
        return true;
    }
    function withdrawRewardAfterUnstake()public returns(bool){
        uint256 totalAmount=reward[msg.sender];
        tokenInstance.transfer(msg.sender,totalAmount);
        reward[msg.sender]=0;
        return true;
    }
    

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}
	function getUserDividends(address userAddress) public view returns (uint256) {
	    
		User storage user = users[userAddress];
		uint256 totalDividends;
		uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(10000))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
				totalDividends = totalDividends.add(dividends);
				
		}
 
		return totalDividends;
	}
    
	function getUserReferrer(address userAddress) public view returns(address) {
		return refusers[userAddress].referrer;
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return refusers[userAddress].bonus;
	}
	
	
	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (refusers[userAddress].level1, refusers[userAddress].level2, refusers[userAddress].level3);
	}
	
	function getUserDownlineRefferal(address userAddress) public view returns(uint256, uint256, uint256) {
		return (refusers[userAddress].ref1, refusers[userAddress].ref2, refusers[userAddress].ref3);
	}

	function getUserReferralWithdraw(address userAddress) public view returns(uint256) {
		return refusers[userAddress].withdrawRef;
	}

	function getUserAvailableBalanceForWithdrawal(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(250).div(100)) {
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
    function withdrawCommission(uint256 _amount)public returns(bool){
        require(msg.sender==owner,"access denied");
        owner.transfer(_amount.mul(1000000));
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