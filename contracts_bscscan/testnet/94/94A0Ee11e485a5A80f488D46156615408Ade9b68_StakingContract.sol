/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-26
*/

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
      uint256 public percentage=1;
      uint256 public totalInvested;
      uint256 public totalDeposits;
      uint256 public totalWithdrawn;
      uint256 public totalUsers;
      uint256 public PERCENTS_DIVIDER=1000000;
      uint256 public TIME_STEP=5 minutes;
      	struct Deposit {
		uint256 amount;
		uint256 amountInBullBNB;
		uint256 withdrawn;
		uint256 start;
		uint256 checkpoint;
		uint256 otherhalfAmount;
		uint256 nextForHalfAmountReleasingTime;
		bool unstaked;
	}

	struct User {
		Deposit[] deposits;
		uint256 a;
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
		
    
		user.deposits.push(Deposit(amount, amount.mul(100000),0, block.timestamp,block.timestamp,0,0,false));
		totalInvested = totalInvested.add(amount);
		totalDeposits = totalDeposits.add(1);
		emit NewDeposit(msg.sender, amount);
          return true;
      }
      
      
      function winthdrawBullBnbTokens(uint256 i)public returns(bool){
        User storage user = users[msg.sender];
        address userAddress=msg.sender;
        
        
        if(user.deposits[i].unstaked){
            require(block.timestamp>user.deposits[i].nextForHalfAmountReleasingTime.add(10 minutes),"you have to wait for 15 days");
            bullBNBToken.transferFrom(owner,userAddress,user.deposits[i].otherhalfAmount.mul(33).div(100));
            user.deposits[i].otherhalfAmount=user.deposits[i].otherhalfAmount.sub(user.deposits[i].otherhalfAmount.mul(33).div(100));
            user.deposits[i].nextForHalfAmountReleasingTime=block.timestamp;
         return true;   
        }
        
        else{
            

		uint256 totalAmount;
		uint256 dividends;
					dividends = (user.deposits[i].amountInBullBNB.mul(percentage).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].checkpoint)).div(5 seconds);
						
						
				if (user.deposits[i].withdrawn.add(dividends) > getMaxPercentage(user.deposits[i].amountInBullBNB) ){
					dividends = getMaxPercentage(user.deposits[i].amountInBullBNB).sub(user.deposits[i].withdrawn);
				}

				totalAmount = totalAmount.add(dividends);
		
             user.deposits[i].withdrawn=user.deposits[i].withdrawn.add(totalAmount);
		user.deposits[i].checkpoint = block.timestamp;
        totalAmount=totalAmount.add(getUserTotalDeposits(userAddress));
        user.deposits[i].otherhalfAmount=user.deposits[i].otherhalfAmount.add(totalAmount.div(2));
		bullBNBToken.transferFrom(owner,msg.sender,totalAmount.div(2));
		totalWithdrawn = totalWithdrawn.add(totalAmount);
		emit Withdrawn(msg.sender, totalAmount);
		return true;
        }
        
      }
      
      function unstake(uint256 i) public returns(bool){
          
        User storage user = users[msg.sender];
        address userAddress=msg.sender;

        winthdrawBullBnbTokens(i);
        
        blrsToken.transferFrom(owner,userAddress,user.deposits[i].amount);
        user.deposits[i].amount=0;
        user.deposits[i].unstaked=true;
        user.deposits[i].nextForHalfAmountReleasingTime=block.timestamp;
        return true;
      }
      
      
      function getMaxPercentage(uint256 amount)public pure returns(uint256){
          return amount.mul(1).div(10000);
      }
      
      
//      function getUserTimeAfterDeposit(address userAddress, uint256 index) public view returns(uint256) {
// 	    User storage user = users[userAddress];

// 		 return();
// 	}
      
      

	function getUserDividends(address userAddress,uint256 i) public view returns (uint256) {
		User storage user = users[userAddress];

        
		uint256 totalDividends;
		uint256 dividends;

        

					dividends = (user.deposits[i].amountInBullBNB.mul(percentage).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].checkpoint)).div(5 seconds);

				if (user.deposits[i].withdrawn.add(dividends) > getMaxPercentage(user.deposits[i].amountInBullBNB)) {
					dividends = getMaxPercentage(user.deposits[i].amountInBullBNB).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);

			

		return totalDividends;
	}
      	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256,uint256) {
	    User storage user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start,user.deposits[index].checkpoint);
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