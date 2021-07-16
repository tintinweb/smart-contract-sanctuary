//SourceUnit: tron.sol

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
		uint256 totalInvestment;
		uint256 directsIncome;
		uint256 roiReferralIncome;
		uint256 currInvestment;
		uint256 dailyIncome;
		uint256 dailyROI;
		uint256 depositTime;
		uint256 incomeLimitLeft;
		uint256 referralCount;
		address referrer;
	}
}

contract MyTron {
    using SafeMath for *;
        address public owner;
        address public masterAccount;
        uint256 private houseFee = 30;
        uint256 private incomeTimes = 30;
        uint256 private incomeDivide = 10;
        uint256 public total_withdraw;
        uint256 public currUserID;
		
        mapping (uint => address) public userList;
        mapping (address => DataStructs.User) public player;
        mapping (address => uint256) public playerTotEarnings;

        /****************************  EVENTS   *****************************************/
        event registerUserEvent(address indexed _playerAddress, address indexed _referrer);
        event investmentEvent(address indexed _playerAddress, uint256 indexed _amount);
        event referralCommissionEvent(address indexed _playerAddress, address indexed _referrer, uint256 indexed amount, uint256 _type);
        event withdrawEvent(address indexed _playerAddress, uint256 indexed amount, uint256 indexed timeStamp);
		
        constructor (address _owner, address _masterAccount ) public {
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

     
        modifier isMinimumAmount(uint256 _trx) {
            require(_trx >= 100000000, "Minimum contribution amount is 100 TRX");
			_;
        }
		
		modifier isMaximumAmount(uint256 _trx) {
            require(_trx <= 100000000000, "maximum contribution amount is 100000 TRX");
			_;
        }
		
        modifier isallowedValue(uint256 _trx) {
            require(_trx % 100000000 == 0, "multiples of 100 TRX please");
            _;
        }
		
        modifier onlyOwner() {
            require(msg.sender == owner, "only Owner");
            _;
        }

        modifier requireUser() { require(isUser(msg.sender)); _; }

        function registerUser(uint256 _referrerID) public isMinimumAmount(msg.value) isMaximumAmount(msg.value) isallowedValue(msg.value) payable 
		{
            require(_referrerID > 0 && _referrerID <= currUserID, "Incorrect Referrer ID");
            address _referrer = userList[_referrerID];
            uint256 amount = msg.value;
			uint256 roiPercent = 50;
			if(amount > 50000000000)
			{
			    roiPercent = 100;
			}
            if(player[msg.sender].id <= 0) 
			{
                currUserID++;
                player[msg.sender].id = currUserID;
                player[msg.sender].depositTime = now;
                player[msg.sender].currInvestment = amount;
                player[msg.sender].incomeLimitLeft = amount.mul(incomeTimes).div(incomeDivide);
                player[msg.sender].totalInvestment = amount;
                player[msg.sender].referrer = _referrer;
				player[msg.sender].dailyROI = roiPercent;
                userList[currUserID] = msg.sender;
                player[_referrer].referralCount = player[_referrer].referralCount.add(1);
                directsReferralBonus(msg.sender, amount);
                emit registerUserEvent(msg.sender, _referrer);
            }
            else 
			{
			
				require(player[msg.sender].incomeLimitLeft == 0, "limit is still remaining");
				_referrer = player[msg.sender].referrer;
				player[msg.sender].incomeLimitLeft = amount.mul(incomeTimes).div(incomeDivide);
                player[msg.sender].depositTime = now;
                player[msg.sender].dailyIncome = 0;
                player[msg.sender].currInvestment = amount;
				player[msg.sender].dailyROI = roiPercent;
                player[msg.sender].totalInvestment = player[msg.sender].totalInvestment.add(amount);
                directsReferralBonus(msg.sender, amount);
            }
			address payable ownerAddr = address(uint160(owner));
			ownerAddr.transfer(amount.mul(houseFee).div(100));
			emit investmentEvent (msg.sender, amount);
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
                        if(player[_nextReferrer].referralCount >= 2) 
						{
                            player[_nextReferrer].directsIncome = player[_nextReferrer].directsIncome.add(amount.mul(2).div(100));
                            emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(2).div(100), 1);
                        }
                    }
                    else 
					{
                        if(player[_nextReferrer].referralCount >= 3) 
						{
                           player[_nextReferrer].directsIncome = player[_nextReferrer].directsIncome.add(amount.mul(1).div(100));
                           emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(1).div(100), 1);
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
		
        function roiReferralBonus(address _playerAddress, uint256 amount) private {
            address _nextReferrer = player[_playerAddress].referrer;
            uint i;
            for(i=0; i < 20; i++) 
			{
                if (_nextReferrer != address(0x0)) 
				{
                    if(i == 0) 
					{
                       player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(30).div(100));
                       emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(30).div(100), 2);
                    }
                    else if(i > 0 && i < 5) 
					{
                        if(player[_nextReferrer].referralCount >= i+1) 
						{
                            player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(10).div(100));
                            emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(10).div(100), 2);
                        }
                    }
                    else if(i > 4 && i < 10) 
					{
                        if(player[_nextReferrer].referralCount >= i+1) 
						{
                            player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(5).div(100));
                            emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(5).div(100), 2);
                        }
                    }
                    else 
					{
                        if(player[_nextReferrer].referralCount >= i+1) 
						{
                            player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.mul(1).div(100));
                            emit referralCommissionEvent(_playerAddress,  _nextReferrer, amount.mul(1).div(100), 2);
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
		
        function withdrawEarnings() requireUser public {
            (uint256 to_payout) = this.payoutOf(msg.sender);
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

            playerTotEarnings[msg.sender] += to_payout;
            total_withdraw += to_payout;

            address payable senderAddr = address(uint160(msg.sender));
            senderAddr.transfer(to_payout);
			
            emit withdrawEvent(msg.sender, to_payout, now);
        }
		
        function payoutOf(address _addr) view external returns(uint256 payout) {
            uint256 earningsLimitLeft = player[_addr].incomeLimitLeft;
			uint256 rPercent = player[_addr].dailyROI;
            if(player[_addr].incomeLimitLeft > 0 ) 
			{
                if(rPercent==50)
				{
				    payout = (player[_addr].currInvestment * 50 * ((block.timestamp - player[_addr].depositTime) / 1 days) / 10000) - player[_addr].dailyIncome;
				}
				else
				{
				    payout = (player[_addr].currInvestment * ((block.timestamp - player[_addr].depositTime) / 1 days) / 100) - player[_addr].dailyIncome;
				}
                if(player[_addr].dailyIncome + payout > earningsLimitLeft) 
				{
                    payout = earningsLimitLeft;
                }
            }
        }
}