/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

/*
*[FUNDS DISTRIBUTION]
 *
 *   - 30% Platform smart contract address for Deposits and Payouts .
 *   - 60% Platform trading Wallet, used to trade Crypto Currency and Profits injected back into the reserve wallet.
 *   - 10% Advertising and Promotion Expenses (Includes expenses for administration and Service)
*/
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.7.0;

contract Bnbnetwork {

	using SafeMath for *;
	
	address public masterAddress;
	address payable public tradingAddress;
	address payable public advertisingAddress;
				
	uint256 constant public MinimumInvest = 1*10**16;  
	uint256 constant public payoutBalance = 30;
	uint256 constant public tradingBalance = 60;		
	uint256 constant public advertisingFee = 10;	
	uint256 constant public percentDiv = 100;			      
    
	uint256 public TotalInvestors;
	uint256 public TotalInvested;
	uint256 public TotalWithdrawn;
	uint256 public TotalDepositCount;
	
	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 timeStamp;
	}

	struct User {
		uint256 id;
		Deposit[] deposits;		
		uint256 checkpoint;		
		uint256 totalinvested;
		uint256 totalwithdrawn;		
		
	}

    mapping(address=>uint256) public balances;
	mapping (address => User) internal users;
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawal(address indexed user, uint256 amount,uint256 timeStamp);
	
	
	constructor(address payable _masterAccount,address payable _tradingAccount,address payable _advertisingAccount) public {
		
		require(!isContract(_masterAccount));
		require(!isContract(_tradingAccount));
		require(!isContract(_advertisingAccount));
		
        
		masterAddress = _masterAccount;
		tradingAddress = _tradingAccount;
		advertisingAddress = _advertisingAccount;
		
		balances[masterAddress]=0;
		balances[tradingAddress]=0;
		balances[advertisingAddress]=0;
		
		
	}

	 modifier isMinimumAmount(uint256 _bnb) {
        require(_bnb >= 1 * 10**16, "Minimum contribution amount is 0.01 BNB");
		_;
    }
		
	modifier isMaximumAmount(uint256 _bnb) {
        require(_bnb <= 500 * 10**18, "Maximum contribution amount is 500 BNB");
		_;
    }	

	function binanceDeposit(uint256 uniqueid) public isMinimumAmount(msg.value) isMaximumAmount(msg.value) payable {

		require(msg.value >= MinimumInvest);

        tradingAddress.transfer(msg.value.mul(tradingBalance).div(percentDiv));
		advertisingAddress.transfer(msg.value.mul(advertisingFee).div(percentDiv));
		
		
		balances[masterAddress]=balances[masterAddress].add(msg.value.mul(payoutBalance).div(percentDiv));
		balances[tradingAddress]=balances[tradingAddress].add(msg.value.mul(tradingBalance).div(percentDiv));
		balances[advertisingAddress]=balances[advertisingAddress].add(msg.value.mul(advertisingFee).div(percentDiv));
       
       if(users[msg.sender].id <= 0){

		User storage user = users[msg.sender];

		user.id = uniqueid;
        if(user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			TotalInvestors = TotalInvestors.add(1);
		}
        user.deposits.push(Deposit(msg.value, 0, block.timestamp));
		user.totalinvested = user.totalinvested.add(msg.value);
		TotalDepositCount = TotalDepositCount.add(1);
		TotalInvested = TotalInvested.add(msg.value);		
		emit NewDeposit(msg.sender, msg.value); 			

	   } else {

        User storage user = users[msg.sender];
		user.deposits.push(Deposit(msg.value, 0, block.timestamp));
		user.totalinvested = user.totalinvested.add(msg.value);
		TotalDepositCount = TotalDepositCount.add(1);
		TotalInvested = TotalInvested.add(msg.value);		
		emit NewDeposit(msg.sender, msg.value); 			

	   }

	}

	  function balanceOf(address balowner) public view returns(uint256){
          return balances[balowner];
      }

     function withdrawCommissions(uint256 amount) public {
		
		uint256 toSend;	
		uint256 totInest;
		User storage user = users[msg.sender];
        
        require(user.deposits.length > 0,'You need to deposit before withdrawal');

		totInest=user.totalinvested;		
		require(totInest>0,'You need to deposit before withdrawal');

		require(balanceOf(masterAddress)>=amount,'balance too low');	   
	    balances[masterAddress]-=amount;	

		toSend = amount;
		address payable senderAddr = address(uint160(msg.sender));
        senderAddr.transfer(toSend);
        user.totalwithdrawn = user.totalwithdrawn.add(amount);
		TotalWithdrawn = TotalWithdrawn.add(toSend);		
		emit Withdrawal(msg.sender, toSend,block.timestamp);
	}
	function getUserData(address userAddress) public view returns(uint256, uint256, uint256, uint256) {
	    User storage user = users[userAddress];
		return (user.id,user.totalinvested, user.totalwithdrawn,user.checkpoint);
	}
	
	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}
	
	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
	    User storage user = users[userAddress];
		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].timeStamp);
	}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }


}

library SafeMath {
	
	function fxpMul(uint256 a, uint256 b, uint256 base) internal pure returns (uint256) {
		return div(mul(a, b), base);
	}
		
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