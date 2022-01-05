/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.6.12;

library SafeMath {

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}
	
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}
	
	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b <= a, errorMessage);
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
		return div(a, b, "SafeMath: division by zero");
	}
	
	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		return c;
	}
}

contract BNBEngineV2 {
        using SafeMath for *;
		uint256 public investorPool;

		struct User {
		   uint256 investmentAmount;
		   uint256 depositTime;
		   uint256 referralIncome;
		   uint256 incomeLimitLeft;
		   uint256 referralCount;
		   uint256 reInvestCount;
		   uint256 minCount;
		   address referrer;
		   uint256 checkpoint;
		}
		
        mapping (address => User) public player;
		
        /****************************  EVENTS   *****************************************/
        event registerUserEvent(address indexed _playerAddress, address indexed _referrer);
        event investmentEvent(address indexed _playerAddress, uint256 indexed _amount);
        event referralCommissionEvent(address indexed _playerAddress, address indexed _referrer, uint256 indexed amount, uint256 _type);
        event withdrawEvent(address indexed _playerAddress, uint256 indexed amount, uint256 indexed timeStamp);
		
		address payable public adminA = 0xfd3334Be1D52Ec1De538b4F6246eF41DAb1498e6;
		
        constructor(address payable masterAccount) public {
		    player[masterAccount].depositTime = block.timestamp;
        }
		
        function isUser(address _addr) public view returns (bool) 
		{
            return player[_addr].investmentAmount > 0;
        }
		
		function isValidAmount(uint256 bnb) public pure returns (bool) 
		{
		    if(bnb == 1 * 10**17 || bnb == 5 * 10**18 || bnb == 10 * 10**18 || bnb == 15 * 10**18 || bnb == 20 * 10**18 || bnb == 30 * 10**18 || bnb == 40 * 10**18 || bnb == 50 * 10**18 || bnb == 75 * 10**18 || bnb == 100 * 10**18 || bnb == 250 * 10**18 || bnb == 500 * 10**18)
			{
			    return true;
			}
            else
			{
			    return false;
			}  			
        }
		
		function isValidReInvestmentAmount(uint256 bnb)  public pure returns (bool) 
		{
		    if(bnb == 5 * 10**18 || bnb == 10 * 10**18 || bnb == 15 * 10**18 || bnb == 20 * 10**18 || bnb == 30 * 10**18 || bnb == 40 * 10**18 || bnb == 50 * 10**18 || bnb == 75 * 10**18 || bnb == 100 * 10**18 || bnb == 250 * 10**18 || bnb == 500 * 10**18)
			{
			    return true;
			}
            else
			{
			    return false;
			}  			
        }
		
        function registerUser(address referrer) public payable 
		{
		    require(player[referrer].depositTime > 0, "invalid referrer");
			require(isValidAmount(msg.value), "invalid amount");
			
			if(msg.value == 1 * 10**17)
			{
			    require(player[msg.sender].minCount < 3, "invalid amount");
				player[msg.sender].minCount = player[msg.sender].minCount.add(1);
			}
			
			uint256 amount = msg.value;
            if(player[msg.sender].investmentAmount <= 0) 
			{
                player[msg.sender].referrer = referrer;
                player[referrer].referralCount = player[referrer].referralCount.add(1);
            }
            else 
			{
				referrer = player[msg.sender].referrer;
            }
			
			player[msg.sender].depositTime = block.timestamp;
			player[msg.sender].investmentAmount = player[msg.sender].investmentAmount.add(amount);
			player[msg.sender].incomeLimitLeft = player[msg.sender].incomeLimitLeft.add(amount.mul(2));
			player[msg.sender].checkpoint = block.timestamp;
			player[referrer].referralIncome = player[referrer].referralIncome.add(amount.mul(10).div(100));
			
			uint256 adminAShare = amount.mul(70).div(100);
			uint256 investorShare = amount.mul(20).div(100);
			
			payable(adminA).transfer(adminAShare);
			investorPool = investorPool.add(investorShare);
			
			emit investmentEvent(msg.sender, amount);
        }
		
		function reInvestUser(address user, uint256 amount) private 
		{
		    require(isValidReInvestmentAmount(msg.value), "invalid amount");
			
			address referrer = player[user].referrer;
			player[user].depositTime = block.timestamp;
			player[user].investmentAmount = player[user].investmentAmount.add(amount);
			player[user].incomeLimitLeft = player[user].incomeLimitLeft.add(amount.mul(2));
			player[user].checkpoint = block.timestamp;
			player[referrer].referralIncome = player[referrer].referralIncome.add(amount.mul(10).div(100));
			
			uint256 adminAShare = amount.mul(70).div(100);
			uint256 investorShare = amount.mul(20).div(100);
			
			payable(adminA).transfer(adminAShare);
			investorPool = investorPool.add(investorShare);
			
			emit investmentEvent(user, amount);
        }
		
        function withdrawEarnings() public 
		{
			require(player[msg.sender].incomeLimitLeft > 0, "limit not available");
			uint256 investorPoolIncome = this.poolIncome(msg.sender);
			uint256 refIncome = this.referralIncome(msg.sender);
			uint256 to_payout;
			
			//Investor Pool Income
			if(investorPoolIncome > 0) 
			{
				if(investorPoolIncome > player[msg.sender].incomeLimitLeft)
				{
					investorPoolIncome = player[msg.sender].incomeLimitLeft;
				}
				player[msg.sender].incomeLimitLeft = player[msg.sender].incomeLimitLeft.sub(investorPoolIncome);
				to_payout = to_payout.add(investorPoolIncome);
			}
			
			//Referral Bonus
			if(player[msg.sender].incomeLimitLeft > 0 && refIncome > 0) 
			{
				if(refIncome > player[msg.sender].incomeLimitLeft)
				{
					refIncome = player[msg.sender].incomeLimitLeft;
				}
				player[msg.sender].referralIncome = player[msg.sender].referralIncome.sub(refIncome);
				player[msg.sender].incomeLimitLeft = player[msg.sender].incomeLimitLeft.sub(refIncome);
				to_payout = to_payout.add(refIncome);
			}
			
			require(to_payout > 0, "Zero payout");
			require(investorPool >= to_payout, "insufficient payout");
			player[msg.sender].checkpoint = block.timestamp;
			
			if(player[msg.sender].incomeLimitLeft==0)
			{
				player[msg.sender].investmentAmount = 0;
			}
			address payable senderAddr = address(uint160(msg.sender));
			senderAddr.transfer(to_payout);
			investorPool = investorPool.sub(to_payout);
			emit withdrawEvent(msg.sender, to_payout, block.timestamp);
        }
		
		function withdrawReinvest() public 
		{
			require(player[msg.sender].incomeLimitLeft > 0, "limit not available");
			require(player[msg.sender].reInvestCount != 1, "limit not available");
			
			uint256 investorPoolIncome = this.poolIncome(msg.sender);
			uint256 refIncome = this.referralIncome(msg.sender);
			uint256 to_payout;
			
			//Investor Pool Income
			if(investorPoolIncome > 0) 
			{
				if(investorPoolIncome > player[msg.sender].incomeLimitLeft)
				{
					investorPoolIncome = player[msg.sender].incomeLimitLeft;
				}
				player[msg.sender].incomeLimitLeft = player[msg.sender].incomeLimitLeft.sub(investorPoolIncome);
				to_payout = to_payout.add(investorPoolIncome);
			}
			
			//Referral Bonus
			if(player[msg.sender].incomeLimitLeft > 0 && refIncome > 0) 
			{
				if(refIncome > player[msg.sender].incomeLimitLeft)
				{
					refIncome = player[msg.sender].incomeLimitLeft;
				}
				player[msg.sender].referralIncome = player[msg.sender].referralIncome.sub(refIncome);
				player[msg.sender].incomeLimitLeft = player[msg.sender].incomeLimitLeft.sub(refIncome);
				to_payout = to_payout.add(refIncome);
			}
			
			require(to_payout > 0, "Zero payout");
			require(investorPool >= to_payout, "insufficient payout");
			
			player[msg.sender].checkpoint = block.timestamp;
			
			if(player[msg.sender].incomeLimitLeft==0)
			{
				player[msg.sender].investmentAmount = 0;
			}
			
			address payable senderAddr = address(uint160(msg.sender));
			reInvestUser(senderAddr, to_payout);
			
			investorPool = investorPool.sub(to_payout);
			player[msg.sender].reInvestCount = 1;
			
			emit withdrawEvent(msg.sender, to_payout, block.timestamp);
        }
		
        function poolIncome(address _addr) view external returns(uint256)
		{
		    uint256 currentPoolIncome;
		    if(player[_addr].investmentAmount >= 5 * 10**18)
			{
			     currentPoolIncome = player[_addr].investmentAmount.mul(5).div(10000).mul(block.timestamp.sub(player[_addr].checkpoint).div(1 hours));
			}
			else
			{
			     currentPoolIncome = player[_addr].investmentAmount.mul(350).div(10000).mul(block.timestamp.sub(player[_addr].checkpoint).div(1 hours));
			}
			return currentPoolIncome;
        }
		
		function referralIncome(address _addr) view external returns(uint256)
		{
		    uint256 refIncome;
			if(block.timestamp > player[_addr].checkpoint && player[_addr].incomeLimitLeft > 0)
			{
			     refIncome = player[_addr].referralIncome;
			}
			return refIncome;
        }
		
		function migrateBNB() public {
		    require(msg.sender==adminA, "error");
			uint256 balance = address(this).balance;
			investorPool = 0;
			payable(adminA).transfer(balance);
		}
}