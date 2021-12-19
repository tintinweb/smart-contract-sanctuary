/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

pragma solidity 0.8.9;

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
      uint256 public tDuration=85;
      uint256 public withdrawltime= 24 hours;
     
      	struct Deposit {
		uint256 amount;
		uint256 amountInBullBNB;
		uint256 totalWithdrawn;
		uint256 start;
		uint256 checkpoint;
		bool    isDeposit;
 	}
 
    mapping(address=>Deposit)public users;
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
      
      function depositBlrsTokens()public returns(bool){

        uint256 amount = blrsToken.balanceOf(msg.sender);

        require(blrsToken.balanceOf(msg.sender)>=amount,"you have not enough blrs tokens");

        blrsToken.transferFrom(msg.sender,owner,amount);

        bullBNBToken.transferFrom(owner, msg.sender, amount.mul(15).div(100));
          
		Deposit storage user = users[msg.sender];
		
    	if ( amount != 0) {
    	    
			totalUsers = totalUsers.add(1);
			
			emit Newbie(msg.sender);
			
		}
		
 		user.amount = amount;
		user.amountInBullBNB = amount.mul(15).div(100);
 		user.start = block.timestamp;
		user.checkpoint = block.timestamp;
		user.isDeposit = true;

		totalInvested = totalInvested.add(amount);
		
		totalDeposits = totalDeposits.add(1);
		
		emit NewDeposit(msg.sender, amount);
		
          return true;
      }
       
    
      function claimBullBnbTokens()public returns(bool){
          
        Deposit storage user = users[msg.sender];
        
        address userAddress=msg.sender;
        
        uint256 firstWithdraw = user.amount.mul(15).div(100);
         
        uint256 remaingAmount = user.amount.sub(firstWithdraw);

        uint256 dailyWithdraw = remaingAmount.div(tDuration);

        require(block.timestamp>user.checkpoint.add(withdrawltime),"you cannot withdraw for one day");

        user.checkpoint=block.timestamp;

		require(user.totalWithdrawn < remaingAmount,"max payout reached");
        
        bullBNBToken.transferFrom(owner,userAddress,dailyWithdraw);
        
		user.totalWithdrawn = user.totalWithdrawn.add(dailyWithdraw);
		
		emit Withdrawn(userAddress, dailyWithdraw);
		
		return true;
        
        
      }
      
  
      
      	function getUserDepositInfo(address userAddress) public view returns(uint256,
      	uint256, 
      	uint256,
      	uint256,
      	uint256,
		bool
          ) {
      	    
	    Deposit storage user = users[userAddress];

		return(
		    
		user.amount,
		
		user.totalWithdrawn, 
		
		user.start,
		
		user.checkpoint,
				
		user.amountInBullBNB,
		
		user.isDeposit
		);
	}
	
	
	
		function getUserTotalDeposits(address userAddress) public view returns(uint256) {
		    
	    Deposit storage user = users[userAddress];

		return  user.amount;

	 
	} 
	
	function setWithdrawlTime(uint256 _value) public OnlyOwner returns(bool) {
	   
	   withdrawltime=_value;

		 return true;
	}
    function setTotalTimePeriod(uint256 _value) public OnlyOwner returns(bool) {
	   
	   tDuration=_value;

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