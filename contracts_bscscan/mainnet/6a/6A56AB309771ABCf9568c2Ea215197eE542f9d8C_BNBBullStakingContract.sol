/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

pragma solidity ^0.8.4;

// SPDX-License-Identifier:MIT
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
contract BNBBullStakingContract{
      using SafeMath for uint256;
      address public owner;
      ERC20 public blrsToken;
      ERC20 public bullBNBToken;
      uint256 public totalInvested;
      uint256 public totalDeposits;
      uint256 public totalWithdrawn;
      uint256 public totalUsers;
      uint256 public PERCENTS_DIVIDER=1000000;
      uint256 public divider=2;
      uint256 public withdrawltime=30 days;
    
      	struct Deposit {
		uint256 amount;
		uint256 amountInBullBNB;
		uint256 withdrawn;
		uint256 start;
		uint256 checkpoint;
		uint256 max;
	}

	struct User {
		Deposit[] deposits;
		uint256 a;
		
	}
    mapping(address=>User)public users;
    event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);

      constructor(address _blrsToken, address _bullBNBToken,address _owner){
          
          blrsToken=ERC20(_blrsToken);
          
          bullBNBToken=ERC20(_bullBNBToken);
          
          owner =_owner;
      }
      
      modifier OnlyOwner(){
          require(msg.sender==owner,"you are not owner");
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
		
		user.deposits.push(Deposit(amount, amount.mul(1000),0, block.timestamp,block.timestamp,getMaxPercentage(amount.mul(1000))));
		
		totalInvested = totalInvested.add(amount);
		
		totalDeposits = totalDeposits.add(1);
		
		emit NewDeposit(msg.sender, amount);
		
          return true;
      }
      
      
      function winthdrawBullBnbTokens(uint256 i)public returns(bool){
          
        User storage user = users[msg.sender];
        
        address userAddress=msg.sender;
        
        uint256 dividends;
        
        require(block.timestamp>user.deposits[i].checkpoint.add(withdrawltime),"you cannot withdraw for a month now");
        
        require(user.deposits[i].withdrawn<user.deposits[i].max,"you cannot withdraw from maximum amount");
        
        dividends=user.deposits[i].max.div(divider);
        
        user.deposits[i].withdrawn=user.deposits[i].withdrawn.add(dividends);
        
        user.deposits[i].checkpoint=block.timestamp;
        
        bullBNBToken.transferFrom(owner,userAddress,dividends);
        
		totalWithdrawn = totalWithdrawn.add(dividends);
		
		emit Withdrawn(userAddress, dividends);
		
		return true;
        
        
      }
      
      function unstake(uint256 i) public returns(bool){
          
        User storage user = users[msg.sender];
        
        address userAddress=msg.sender;
        
        require(block.timestamp> user.deposits[i].start.add(withdrawltime),"you cannot unstake for a month now");
        
        blrsToken.transferFrom(owner,userAddress,user.deposits[i].amount);
        
        user.deposits[i].amount=0;
        
        return true;
        
      }
      
      
      function getMaxPercentage(uint256 amount)public view returns(uint256){
          
          return amount.mul(1).div(10000).div(divider);
          
      }
	
      	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256,
      	uint256, 
      	uint256,
      	uint256,
      	uint256,
      	uint256) {
      	    
	    User storage user = users[userAddress];

		return(
		    
		user.deposits[index].amount,
		
		user.deposits[index].withdrawn, 
		
		user.deposits[index].start,
		
		user.deposits[index].checkpoint,
		
		user.deposits[index].max,
		
		user.deposits[index].amountInBullBNB
		
		);
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
	
	function changeDivider(uint256 _value)public OnlyOwner returns(bool){
	    
	    divider=_value;
	    
	    return true;
	}
	
	function setFirstWithdrawlTime(uint256 _value) public OnlyOwner returns(bool) {
	   
	   withdrawltime=_value;

		 return true;
	}
	
	function changeBlrsToken(address _token)public OnlyOwner returns(bool){
	    
	    blrsToken=ERC20(_token);
	    
	    return true;
	}
	function changeBullBnbToken(address _token)public OnlyOwner returns(bool){
	    
	    bullBNBToken=ERC20(_token);
	    
	    return true;
	}
	
	function changeOwnership(address _owner)public OnlyOwner returns(bool){
	    
	    owner=_owner;
	    
	    return true;
	}

	function isContract(address addr) internal view returns (bool) {
	    
        uint size;
        
        assembly { size := extcodesize(addr) }
        
        return size > 0;
    }
    
}