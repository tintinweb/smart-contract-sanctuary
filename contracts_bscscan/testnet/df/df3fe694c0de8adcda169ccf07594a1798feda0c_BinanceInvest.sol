/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

pragma solidity 0.5.4;

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

library DataStructs {
	struct User {
		uint256 id;
		uint256 directsIncome;
		uint256 roiReferralIncome;
		uint256 currInvestment;
		uint256 dailyIncome;
		uint256 vipPoolIncome;
		uint256 poolIncomeWithdrawal;
		uint256 holdingIncome;
		uint256 withdrawableHoldingIncome;
		uint256 depositTime;
		uint256 incomeLimitLeft;
		uint256 referralCount;
		address referrer;
		uint256 checkpoint;
	}
}

contract BinanceInvest {
    using SafeMath for *;
        address payable public owner;
        address public masterAccount;
        uint256 private houseFee       = 45;
        uint256 private incomeTimes    = 3;
		uint256 private maxHoldPercent = 50;
		uint256 private vipPoolPercent = 2;
		uint256 public pool_next_draw = block.timestamp + 1 weeks;
		uint private timeStep = 5 days;
        uint256 public currUserID;
		uint256 public pool_balance;
		address[] private vipAddress;
		
        mapping (uint => address) public userList;
        mapping (address => DataStructs.User) public player;
        mapping (address => uint256) public playerTotEarnings;
		mapping (address => bool) private isvipAddress;
		

        /****************************  EVENTS   *****************************************/
        event registerUserEvent(address indexed _playerAddress, address indexed _referrer);
        event investmentEvent(address indexed _playerAddress, uint256 indexed _amount);
        event referralCommissionEvent(address indexed _playerAddress, address indexed _referrer, uint256 indexed amount, uint256 _type);
        event withdrawEvent(address indexed _playerAddress, uint256 indexed amount, uint256 indexed timeStamp);
		
        constructor (address payable _owner, address payable _masterAccount ) public {
             owner = _owner;
             masterAccount = _masterAccount;
             currUserID = 0;
             currUserID++;
             player[masterAccount].id = currUserID;
             userList[currUserID] = masterAccount;
        }
		
        function isUser(address _addr) public view returns (bool) {
            return player[_addr].id > 0;
        }

        modifier isMinimumAmount(uint256 _bnb) {
            require(_bnb >= 1 * 10**17, "Minimum contribution amount is 0.1 BNB");
			_;
        }
		
		modifier isMaximumAmount(uint256 _bnb) {
            require(_bnb <= 500 * 10**18, "maximum contribution amount is 500 BNB");
			_;
        }
     
        modifier onlyOwner() {
            require(msg.sender == owner, "only Owner");
            _;
        }

        modifier requireUser() { require(isUser(msg.sender)); _; }

        function registerUser(uint256 _referrerID) public isMinimumAmount(msg.value) isMaximumAmount(msg.value) payable 
		{
            require(_referrerID > 0 && _referrerID <= currUserID, "Incorrect Referrer ID");
            address _referrer = userList[_referrerID];
            uint256 amount = msg.value;
            if(player[msg.sender].id <= 0) 
			{
                currUserID++;
                player[msg.sender].id = currUserID;
                player[msg.sender].depositTime = now;
                player[msg.sender].currInvestment = amount;
                player[msg.sender].incomeLimitLeft = amount.mul(incomeTimes);
                player[msg.sender].referrer = _referrer;
				player[msg.sender].checkpoint = block.timestamp;
                userList[currUserID] = msg.sender;
                player[_referrer].referralCount = player[_referrer].referralCount.add(1);
                directsReferralBonus(msg.sender, amount);
                emit registerUserEvent(msg.sender, _referrer);
            }
            else 
			{
				require(player[msg.sender].incomeLimitLeft == 0, "limit is still remaining");
				_referrer = player[msg.sender].referrer;
				player[msg.sender].incomeLimitLeft = amount.mul(incomeTimes);
                player[msg.sender].depositTime = now;
                player[msg.sender].dailyIncome = 0;
				player[msg.sender].vipPoolIncome = 0;
				player[msg.sender].poolIncomeWithdrawal = 0;
				player[msg.sender].checkpoint = block.timestamp;
                directsReferralBonus(msg.sender, amount);
				
				if(amount >= player[msg.sender].currInvestment.mul(2))
				{
					player[msg.sender].withdrawableHoldingIncome = player[msg.sender].withdrawableHoldingIncome.add(player[msg.sender].holdingIncome);
					player[msg.sender].holdingIncome = 0;
				}
				else
				{
					player[msg.sender].holdingIncome = 0;
				}
				player[msg.sender].currInvestment = amount;
				
            }
			
			owner.transfer(amount.mul(houseFee).div(100));
			pool_balance += amount.mul(vipPoolPercent).div(100);
			
			if(pool_next_draw <= block.timestamp)
			{
			    drawPool();
			}
			if(amount >= 15 * 10**18)
			{
			    vipAddress.push(msg.sender);
			    isvipAddress[msg.sender] = true;
			}
			else
			{
			     if(isvipAddress[msg.sender])
				 {
				    for (uint256 i = 0; i < vipAddress.length; i++) {
						if (vipAddress[i] == msg.sender) {
							vipAddress[i] = vipAddress[vipAddress.length - 1];
							vipAddress.pop();
							break;
						}
					}
				 }
				 isvipAddress[msg.sender] = false;
			}
			emit investmentEvent(msg.sender, amount);
        }
		
		function drawPool() private {
			if(vipAddress.length > 0)
			{
				uint256 perAddress  = pool_balance.div(vipAddress.length);
				for (uint256 i = 0; i < vipAddress.length; i++) 
				{
				    if(perAddress > player[vipAddress[i]].incomeLimitLeft)
					{
					     pool_balance = pool_balance.sub(player[vipAddress[i]].incomeLimitLeft);
						 player[vipAddress[i]].vipPoolIncome = player[vipAddress[i]].vipPoolIncome.add(player[vipAddress[i]].incomeLimitLeft);
					     player[vipAddress[i]].incomeLimitLeft = 0;
					}
					else
					{
					     pool_balance = pool_balance.sub(perAddress);
						 player[vipAddress[i]].vipPoolIncome = player[vipAddress[i]].vipPoolIncome.add(perAddress);
					     player[vipAddress[i]].incomeLimitLeft = player[vipAddress[i]].incomeLimitLeft.sub(perAddress);
					}
				}
			}
			pool_next_draw = pool_next_draw + 1 weeks;
		}
		
        function directsReferralBonus(address _playerAddress, uint256 amount) private 
		{
            address _nextReferrer = player[_playerAddress].referrer;
            uint i;
            for(i=0; i < 3; i++) 
			{
                if (_nextReferrer != address(0x0)) 
				{
                    if(i == 0) 
					{
						 player[_nextReferrer].directsIncome = player[_nextReferrer].directsIncome.add(amount.mul(10).div(100));
						 emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(10).div(100), 1);
                    }
                    else if(i == 1 ) 
					{
                        player[_nextReferrer].directsIncome = player[_nextReferrer].directsIncome.add(amount.mul(2).div(100));
                        emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(2).div(100), 1);
                    }
                    else 
					{
                        player[_nextReferrer].directsIncome = player[_nextReferrer].directsIncome.add(amount.mul(1).div(100));
                        emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(1).div(100), 1);
                    }
                }
                else 
				{
                    break;
                }
                _nextReferrer = player[_nextReferrer].referrer;
            }
        }
		
        function roiReferralBonus(address _playerAddress, uint256 amount) private 
		{
            address _nextReferrer = player[_playerAddress].referrer;
            uint i;
            for(i=0; i < 6; i++) 
			{
                if (_nextReferrer != address(0x0)) 
				{
                    if(i == 0) 
					{
					   if(player[_nextReferrer].referralCount >= 1) 
					   {
					       player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(30).div(100));
                           emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(30).div(100), 2);
					   }
                    }
                    else if(i == 1) 
					{
                        if(player[_nextReferrer].referralCount >= 2) 
					    {
					       player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(10).div(100));
                           emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(10).div(100), 2);
					    }
                    }
                    else if(i == 2) 
					{
                        if(player[_nextReferrer].referralCount >= 3) 
					    {
					       player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(10).div(100));
                           emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(10).div(100), 2);
					    }
                    }
					else if(i == 3) 
					{
                        if(player[_nextReferrer].referralCount >= 4) 
					    {
					       player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(7).div(100));
                           emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(7).div(100), 2);
					    }
                    }
					else if(i == 4) 
					{
                        if(player[_nextReferrer].referralCount >= 5) 
					    {
					       player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(5).div(100));
                           emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(5).div(100), 2);
					    }
                    }
					else if(i == 5) 
					{
                       if(player[_nextReferrer].referralCount >= 6) 
					    {
					       player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(3).div(100));
                           emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(3).div(100), 2);
					    }
                    }
                }
                else 
				{
                    break;
                }
                _nextReferrer = player[_nextReferrer].referrer;
            }
        }
		
		function withdrawPoolEarnings() requireUser public {
            require(player[msg.sender].vipPoolIncome.sub(player[msg.sender].poolIncomeWithdrawal) > 0, "Limit not available");
			
			uint256 payout = player[msg.sender].vipPoolIncome.sub(player[msg.sender].poolIncomeWithdrawal);
			player[msg.sender].poolIncomeWithdrawal = player[msg.sender].poolIncomeWithdrawal.add(payout);
			
			msg.sender.transfer(payout);
			
			if(player[msg.sender].incomeLimitLeft==0){
			     if(isvipAddress[msg.sender])
				 {
				    for (uint256 i = 0; i < vipAddress.length; i++) {
						if (vipAddress[i] == msg.sender) {
							vipAddress[i] = vipAddress[vipAddress.length - 1];
							vipAddress.pop();
							break;
						}
					}
				 }
				 isvipAddress[msg.sender] = false;
			}
			
		    if(pool_next_draw <= block.timestamp)
			{
			    drawPool();
			}
			
			emit withdrawEvent(msg.sender, payout, block.timestamp);
        }
	
		function withdrawHoldingEarnings() requireUser public {
            require(player[msg.sender].withdrawableHoldingIncome > 0, "Limit not available");
			
			uint256 payout = player[msg.sender].withdrawableHoldingIncome;
			player[msg.sender].withdrawableHoldingIncome = player[msg.sender].withdrawableHoldingIncome.sub(payout);
			
			msg.sender.transfer(payout);
			
			if(pool_next_draw <= block.timestamp)
			{
			    drawPool();
			}
            emit withdrawEvent(msg.sender, payout, block.timestamp);
        }
		
        function withdrawEarnings() requireUser public {
            (uint256 to_payout) = this.payoutOf(msg.sender);
			(uint256 holding_payout) = this.holdingOf(msg.sender);
			
            require(player[msg.sender].incomeLimitLeft > 0, "Limit not available");
			
            if(to_payout > 0) 
			{
                if(to_payout > player[msg.sender].incomeLimitLeft)
				{
                    to_payout = player[msg.sender].incomeLimitLeft;
                }
                player[msg.sender].dailyIncome += to_payout;
                player[msg.sender].incomeLimitLeft -= to_payout;
                roiReferralBonus(msg.sender, to_payout);
            }
			
			//Holding Income
			if(holding_payout > 0) 
			{
                if(holding_payout > player[msg.sender].incomeLimitLeft)
				{
                    holding_payout = player[msg.sender].incomeLimitLeft;
                }
                player[msg.sender].holdingIncome += holding_payout;
                player[msg.sender].incomeLimitLeft -= holding_payout;
            }
			
            //Direct Sponsor Bonus
            if(player[msg.sender].incomeLimitLeft > 0 && player[msg.sender].directsIncome > 0) 
			{
                uint256 direct_bonus = player[msg.sender].directsIncome;
                if(direct_bonus > player[msg.sender].incomeLimitLeft) {
                    direct_bonus = player[msg.sender].incomeLimitLeft;
                }
                player[msg.sender].directsIncome -= direct_bonus;
                player[msg.sender].incomeLimitLeft -= direct_bonus;
                to_payout += direct_bonus;
            }
			
            //Match payout
            if(player[msg.sender].incomeLimitLeft > 0  && player[msg.sender].roiReferralIncome > 0) 
			{
                uint256 match_bonus = player[msg.sender].roiReferralIncome;
                if(match_bonus > player[msg.sender].incomeLimitLeft) {
                    match_bonus = player[msg.sender].incomeLimitLeft;
                }
                player[msg.sender].roiReferralIncome -= match_bonus;
                player[msg.sender].incomeLimitLeft -= match_bonus;
                to_payout += match_bonus;
            }
			
            require(to_payout > 0, "Zero payout");
			player[msg.sender].checkpoint = block.timestamp;
            playerTotEarnings[msg.sender] += to_payout;
            address payable senderAddr = address(uint160(msg.sender));
            senderAddr.transfer(to_payout);
			
			if(pool_next_draw <= block.timestamp)
			{
			    drawPool();
			}
			
			if(player[msg.sender].incomeLimitLeft==0)
			{
			     if(isvipAddress[msg.sender])
				 {
				    for (uint256 i = 0; i < vipAddress.length; i++) {
						if (vipAddress[i] == msg.sender) {
							vipAddress[i] = vipAddress[vipAddress.length - 1];
							vipAddress.pop();
							break;
						}
					}
				 }
				 isvipAddress[msg.sender] = false;
			}
            emit withdrawEvent(msg.sender, to_payout, now);
        }
		
        function payoutOf(address _addr) view external returns(uint256 payout) 
		{
            uint256 earningsLimitLeft = player[_addr].incomeLimitLeft;
			uint256 rPercent = 50;
			if(player[_addr].currInvestment >= 10 * 10**18)
			{
			     rPercent = 75;
			}
            if(player[_addr].incomeLimitLeft > 0 ) 
			{
                payout = (player[_addr].currInvestment * rPercent * ((block.timestamp - player[_addr].depositTime) / 1 days) / 10000) - player[_addr].dailyIncome;
                if(player[_addr].dailyIncome + payout > earningsLimitLeft) 
				{
                    payout = earningsLimitLeft;
                }
            }
        }
		
		function holdingOf(address _addr) view external returns(uint256 payout) 
		{
		    uint256 earningsLimitLeft = player[_addr].incomeLimitLeft;
		    uint256 holdingPercent = (block.timestamp.sub(uint(player[_addr].checkpoint))).div(timeStep.div(2)).mul(5);
			if (holdingPercent > maxHoldPercent) 
			{
				holdingPercent = maxHoldPercent;
			}
			payout = (player[_addr].currInvestment * holdingPercent * ((block.timestamp - player[_addr].checkpoint) / 1 days) / 10000);
			if(payout > earningsLimitLeft) 
			{
				 payout = earningsLimitLeft;
			}
        }
		
		function getHoldingPercentRate(address _addr) public view returns (uint) 
		{
			if(player[_addr].id <= 0 && player[_addr].incomeLimitLeft > 0) 
			{
				uint256 holdingPercent = (block.timestamp.sub(uint(player[_addr].checkpoint))).div(timeStep.div(2)).mul(5);
				if (holdingPercent > maxHoldPercent) 
				{
				    holdingPercent = maxHoldPercent;
				}
				return holdingPercent; 
			}
			else 
			{
				return 0;
			}
		}
		
		function isVIP(address _addr) public view returns (bool) {
			return isvipAddress[_addr];
		}
}