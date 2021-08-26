/**
 *Submitted for verification at BscScan.com on 2021-08-25
*/

pragma solidity ^0.8.4;


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
 interface ERC20 {
    function balanceOf(address _owner) view external  returns (uint256 balance);
    function transfer(address _to, uint256 _value) external  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external  returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) view external  returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract StakingContract{
      using SafeMath for uint256;
      address public owner;
      ERC20 public blrsToken;
      ERC20 public bullBNBToken;
      uint256 public daily=56;
      uint256 public oneMonth=300;
      uint256 public twoMonth=670;
      uint256 public threeMonth=1000;
      uint256 public totalInvested;
      uint256 public totalDeposits;
      uint256 public totalWithdrawn;
      uint256 public totalUsers;
      uint256 public PERCENTS_DIVIDER=10000;
      uint256 public TIME_STEP=5 minutes;
      	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
		uint256 checkpoint;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
	}
      mapping(address=>User)public users;
    event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

      constructor(address _blrsToken, address _bullBNBToken){
          blrsToken=ERC20(_blrsToken);
          bullBNBToken=ERC20(_bullBNBToken);
          owner =msg.sender;
      }
      modifier OnlyOwner(){
          require(msg.sender==owner,"ypu are not owner");
          _;
      }
      
      function stakeBlrsTokens(uint256 amount)public returns(bool){
          require(blrsToken.balanceOf(msg.sender)>amount,"ypu have not enough blrs tokens");
          blrsToken.transferFrom(msg.sender,owner,amount);
          
		User storage user = users[msg.sender];
		
	if (user.deposits.length == 0) {
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}
    
		user.deposits.push(Deposit(amount, 0, block.timestamp,block.timestamp));
		totalInvested = totalInvested.add(amount);
		totalDeposits = totalDeposits.add(1);
		emit NewDeposit(msg.sender, amount);
          return true;
      }
      function unStakeBullBnbTokens(uint256 i)public returns(bool){
          
        User storage user = users[msg.sender];
        address userAddress=msg.sender;
// 		uint256 userPercentRate = getUserDividends(msg.sender);

		uint256 totalAmount;
		uint256 dividends;

// 		for (uint256 i = 0; i < user.deposits.length; i++) {

// 			if (user.deposits[i].withdrawn < (user.deposits[i].amount.mul(250)).div(PERCENTS_DIVIDER)) {

// 				if (user.deposits[i].start > user.checkpoint) {

// 					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
// 						.mul(block.timestamp.sub(user.deposits[i].start))
// 						.div(TIME_STEP);

// 				} else {

// 					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
// 						.mul(block.timestamp.sub(user.checkpoint))
// 						.div(TIME_STEP);

// 				}

// 				if (user.deposits[i].withdrawn.add(dividends) > (user.deposits[i].amount.mul(250)).div(PERCENTS_DIVIDER)) {
// 					dividends = ((user.deposits[i].amount.mul(250)).div(PERCENTS_DIVIDER)).sub(user.deposits[i].withdrawn);
// 				}

// 				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
// 				totalAmount = totalAmount.add(dividends);

// 			}
// 		}
		
		
// 		for (uint256 i = 0; i < user.deposits.length; i++) {

// 			if (user.deposits[i].withdrawn < (user.deposits[i].amount.mul(250)).div(PERCENTS_DIVIDER)) {
            uint256 userPercentRate=getUserPercentage(userAddress,i);
				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(getUserTimeAfterDeposit(userAddress,i));

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(getUserTimeAfterDeposit(userAddress,i));

				}

				totalAmount = totalAmount.add(dividends);

				/// no update of withdrawn because that is view function

			
		

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;
        totalAmount=totalAmount.add(getUserTotalDeposits(userAddress));
		bullBNBToken.transferFrom(owner,msg.sender,totalAmount);

		totalWithdrawn = totalWithdrawn.add(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);
		delete users[userAddress];
		return true;
      }
      
      
     function getUserTimeAfterDeposit(address userAddress, uint256 index) public view returns(uint256) {
	    User storage user = users[userAddress];

		 return(block.timestamp.sub(user.deposits[index].checkpoint));
	}
      
      
     function getUserPercentage(address userAddress,uint256 index) view public returns(uint256){
         uint256 timePassed=getUserTimeAfterDeposit(userAddress,index);
         if(timePassed<30 days ){
             return daily;
         }
         else if(timePassed<60  days){
             return oneMonth;
         }
         else if(timePassed<90 days){
             return twoMonth;
         }
         else{
             return threeMonth;
         }
         
         
     }

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

        
		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

// 			if (user.deposits[i].withdrawn < (user.deposits[i].amount.mul(250)).div(PERCENTS_DIVIDER)) {
            uint256 userPercentRate=getUserPercentage(userAddress,i);
				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(getUserTimeAfterDeposit(userAddress,i));

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(getUserTimeAfterDeposit(userAddress,i));

				}

				if (user.deposits[i].withdrawn.add(dividends) > (user.deposits[i].amount.mul(2)).div(PERCENTS_DIVIDER)) {
					dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);

				/// no update of withdrawn because that is view function

			}

// 		}

		return totalDividends;
	}
      	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256,uint256) {
	    User storage user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start,user.deposits[index].start);
	}
	
	
	
		function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}

		return amount;
	}
	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
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