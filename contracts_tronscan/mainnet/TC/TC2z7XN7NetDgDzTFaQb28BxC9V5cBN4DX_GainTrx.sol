//SourceUnit: gaintrx(1).sol

pragma solidity 0.5.10;

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

  
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

 
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract GainTrx {
    using SafeMath for uint256;
    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
		uint256 direct_bonus; 
		mapping(uint256 => uint256) levelRefCount;
		mapping(uint256 => uint256) returnRefCount;			
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
		uint256 total_earning;
    }

    address payable public owner;
    
    mapping(address => uint) public paid_deposit;

    mapping(address => User) public users;
	
    uint256[] public cycles;
    uint8[] public ref_bonuses;                     // 1 => 1%

    uint8[] public pool_bonuses;                    // 1 => 1%
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;
	uint256[] public REFERRAL_PERCENTS = [200, 20, 30, 40, 50];

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount, uint256 level);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor(address payable _owner) public {
        owner = _owner;
        
        ref_bonuses.push(5);
        ref_bonuses.push(6);
        ref_bonuses.push(7);
        ref_bonuses.push(8);
        ref_bonuses.push(9);
        ref_bonuses.push(10);
        ref_bonuses.push(11);
        ref_bonuses.push(12);
        ref_bonuses.push(13);
        ref_bonuses.push(14);
       

        pool_bonuses.push(50);
        pool_bonuses.push(30);
        pool_bonuses.push(20);
       
		cycles.push(500000000);
        cycles.push(1000000000);
        cycles.push(5000000000);
        cycles.push(10000000000);
		cycles.push(25000000000);
        cycles.push(50000000000);
    }

    function() payable external {
        _deposit(msg.sender, msg.value);
    }

    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++;

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }
	
	
	function withdrawLostTRXFromBalance(address payable _sender) public {
        require(msg.sender == owner, "onlyOwner");
        _sender.transfer(address(this).balance);
    }

    function _deposit(address _addr, uint256 _amount) private {
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            require((users[_addr].total_payouts >= this.maxPayoutOf((users[_addr].deposit_amount-paid_deposit[_addr])) || users[_addr].deposit_payouts >= this.maxPayoutOf((users[_addr].deposit_amount-paid_deposit[_addr])).div(2)), "Deposit already exists");
            require(_amount >= (users[_addr].deposit_amount-paid_deposit[_addr]), "Bad amount");
            paid_deposit[_addr]=users[_addr].deposit_amount;
        }
        else {require(_amount >= 500 trx, "Bad amount"); 
        paid_deposit[_addr]=0;
        }
        
        users[_addr].payouts = 0;
        users[_addr].deposit_amount += _amount;
        users[_addr].deposit_payouts = 0;
		
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;
        
		
        total_deposited += _amount;
        
        emit NewDeposit(_addr, _amount);

        if(users[_addr].upline != address(0)) {
			address upline = users[_addr].upline;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(1000);
					
					if(users[upline].total_earning < users[upline].total_deposits.mul(4)) 
					{
						if(i == 4)
						{
							if(users[upline].referrals >=2)
							{
						  
							
							
								uint256 to_payout = users[upline].total_deposits.mul(4) - users[upline].total_earning;
								
								if(amount <= to_payout) 
								{
									users[upline].levelRefCount[i] = users[upline].levelRefCount[i] +1;
								users[upline].direct_bonus = users[upline].direct_bonus.add(amount);
								users[upline].total_earning += amount;
								emit DirectPayout(upline, _addr, amount);
								}
								else
								{
									users[upline].levelRefCount[i] = users[upline].levelRefCount[i] +1;
									users[upline].direct_bonus = users[upline].direct_bonus.add(to_payout);
									users[upline].total_earning += to_payout;
									emit DirectPayout(upline, _addr, to_payout);
								}
							
								
							
							
							}
						}
						else
						{
							
							
							uint256	to_payout = users[upline].total_deposits.mul(4) - users[upline].total_earning;
								
								if(amount <= to_payout) 
								{
								users[upline].levelRefCount[i] = users[upline].levelRefCount[i] +1;
								users[upline].direct_bonus = users[upline].direct_bonus.add(amount);
								users[upline].total_earning += amount;
								emit DirectPayout(upline, _addr, amount);
								}
								else
								{
									users[upline].levelRefCount[i] = users[upline].levelRefCount[i] +1;
									users[upline].direct_bonus = users[upline].direct_bonus.add(to_payout);
									users[upline].total_earning += to_payout;
									emit DirectPayout(upline, _addr, to_payout);
								}
							
							
						}
					}
					
					upline = users[upline].upline;
					
				}else break;
			}
		
		
            

            
        }

        _pollDeposits(_addr, _amount);

        if(pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
        }

        owner.transfer(_amount *10/ 100);
        
        
    }

    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount * 3 / 100;

        address upline = users[_addr].upline;

        if(upline == address(0)) return;
        
        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top[j] == upline) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }

                pool_top[i] = upline;

                break;
            }
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
			if(users[up].total_earning < users[up].total_deposits.mul(4)) 
			{
				if(i == 0)
				{
							
					
						uint256 bonus = _amount * ref_bonuses[i] / 100;
						
					uint256	to_payout = users[up].total_deposits.mul(4) - users[up].total_earning;
								
						if(bonus <= to_payout) 
						{
							users[up].match_bonus += bonus;
							users[up].total_earning += bonus;
							users[up].returnRefCount[i] = users[up].returnRefCount[i] +bonus;
							
							emit MatchPayout(up, _addr, bonus,1);
						}
						else
						{
							users[up].match_bonus += to_payout;
							users[up].total_earning += to_payout;
							users[up].returnRefCount[i] = users[up].returnRefCount[i] +to_payout;
							
							emit MatchPayout(up, _addr, to_payout,1);
						}
					
				}
				else if(i == 1)
				{
					
						uint256 bonus = _amount * ref_bonuses[i] / 100;
						
					uint256	to_payout = users[up].total_deposits.mul(4) - users[up].total_earning;
								
						if(bonus <= to_payout) 
						{
							users[up].match_bonus += bonus;
							users[up].total_earning += bonus;
							users[up].returnRefCount[i] = users[up].returnRefCount[i] +bonus;
							
							emit MatchPayout(up, _addr, bonus,2);
						}
						else
						{
							users[up].match_bonus += to_payout;
							users[up].total_earning += to_payout;
							users[up].returnRefCount[i] = users[up].returnRefCount[i] +to_payout;
							//users[up].transfer(to_payout);
							emit MatchPayout(up, _addr, to_payout,2);
						}
					
				}
				else if(i == 2)
				{
					
						uint256 bonus = _amount * ref_bonuses[i] / 100;
						
					uint256	to_payout = users[up].total_deposits.mul(4) - users[up].total_earning;
								
						if(bonus <= to_payout) 
						{
							users[up].match_bonus += bonus;
							users[up].total_earning += bonus;
							users[up].returnRefCount[i] = users[up].returnRefCount[i] +bonus;
							//users[up].transfer(bonus);
							emit MatchPayout(up, _addr, bonus,3);
						}
						else
						{
							users[up].match_bonus += to_payout;
							users[up].total_earning += to_payout;
							users[up].returnRefCount[i] = users[up].returnRefCount[i] +to_payout;
							//users[up].transfer(to_payout);
							emit MatchPayout(up, _addr, to_payout,3);
						}
					
				}
				else if(i == 3)
				{
					
						uint256 bonus = _amount * ref_bonuses[i] / 100;
						
					uint256	to_payout = users[up].total_deposits.mul(4) - users[up].total_earning;
								
						if(bonus <= to_payout) 
						{
							users[up].match_bonus += bonus;
							users[up].total_earning += bonus;
							users[up].returnRefCount[i] = users[up].returnRefCount[i] +bonus;
							//users[up].transfer(bonus);
							emit MatchPayout(up, _addr, bonus,4);
						}
						else
						{
							users[up].match_bonus += to_payout;
							users[up].total_earning += to_payout;
							users[up].returnRefCount[i] = users[up].returnRefCount[i] +to_payout;
							//users[up].transfer(to_payout);
							emit MatchPayout(up, _addr, to_payout,4);
						}
					
				}
				else if(i == 4)
				{
					if(users[up].referrals >= 2) {
						uint256 bonus = _amount * ref_bonuses[i] / 100;
						
					uint256	to_payout = users[up].total_deposits.mul(4) - users[up].total_earning;
								
						if(bonus <= to_payout) 
						{
							users[up].match_bonus += bonus;
							users[up].total_earning += bonus;
							users[up].returnRefCount[i] = users[up].returnRefCount[i] +bonus;
							//users[up].transfer(bonus);
							emit MatchPayout(up, _addr, bonus,5);
						}
						else
						{
							users[up].match_bonus += to_payout;
							users[up].total_earning += to_payout;
							users[up].returnRefCount[i] = users[up].returnRefCount[i] +to_payout;
							//users[up].transfer(to_payout);
							emit MatchPayout(up, _addr, to_payout,5);
						}
					}
				}
				else if(i == 5)
				{
					
						uint256 bonus = _amount * ref_bonuses[i] / 100;
						
					uint256	to_payout = users[up].total_deposits.mul(4) - users[up].total_earning;
								
						if(bonus <= to_payout) 
						{
							users[up].match_bonus += bonus;
							users[up].total_earning += bonus;
							users[up].returnRefCount[i] = users[up].returnRefCount[i] +bonus;
							//users[up].transfer(bonus);
							emit MatchPayout(up, _addr, bonus,6);
						}
						else
						{
							users[up].match_bonus += to_payout;
							users[up].total_earning += to_payout;
							users[up].returnRefCount[i] = users[up].returnRefCount[i] +to_payout;
							//users[up].transfer(to_payout);
							emit MatchPayout(up, _addr, to_payout,6);
						}
					
				}
				else if(i == 6)
				{
					if(users[up].referrals >= 3) {
						uint256 bonus = _amount * ref_bonuses[i] / 100;
						
					uint256	to_payout = users[up].total_deposits.mul(4) - users[up].total_earning;
								
						if(bonus <= to_payout) 
						{
							users[up].match_bonus += bonus;
							users[up].total_earning += bonus;
							users[up].returnRefCount[i] = users[up].returnRefCount[i] +bonus;
							//users[up].transfer(bonus);
							emit MatchPayout(up, _addr, bonus,7);
						}
						else
						{
							users[up].match_bonus += to_payout;
							users[up].total_earning += to_payout;
							users[up].returnRefCount[i] = users[up].returnRefCount[i] +to_payout;
							//users[up].transfer(to_payout);
							emit MatchPayout(up, _addr, to_payout,7);
						}
					}
				}
				else if(i == 7)
				{
					if(users[up].referrals >= 4) {
						uint256 bonus = _amount * ref_bonuses[i] / 100;
						
					uint256	to_payout = users[up].total_deposits.mul(4) - users[up].total_earning;
								
						if(bonus <= to_payout) 
						{
							users[up].match_bonus += bonus;
							users[up].total_earning += bonus;
							users[up].returnRefCount[i] = users[up].returnRefCount[i] +bonus;
							//users[up].transfer(bonus);
							emit MatchPayout(up, _addr, bonus,8);
						}
						else
						{
							users[up].match_bonus += to_payout;
							users[up].total_earning += to_payout;
							users[up].returnRefCount[i] = users[up].returnRefCount[i] +to_payout;
							//users[up].transfer(to_payout);
							emit MatchPayout(up, _addr, to_payout,8);
						}
					}
				}
				else if(i == 8)
				{
					if(users[up].referrals >= 5) {
						uint256 bonus = _amount * ref_bonuses[i] / 100;
						
					uint256	to_payout = users[up].total_deposits.mul(4) - users[up].total_earning;
								
						if(bonus <= to_payout) 
						{
							users[up].match_bonus += bonus;
							users[up].total_earning += bonus;
							users[up].returnRefCount[i] = users[up].returnRefCount[i] +bonus;
							
							//users[up].transfer(bonus);
							emit MatchPayout(up, _addr, bonus,9);
						}
						else
						{
							users[up].match_bonus += to_payout;
							users[up].total_earning += to_payout;
							users[up].returnRefCount[i] = users[up].returnRefCount[i] +to_payout;
							
							//users[up].transfer(to_payout);
							emit MatchPayout(up, _addr, to_payout,9);
						}
					}
				}
				else if(i == 9)
				{
					if(users[up].referrals >= 6) {
						uint256 bonus = _amount * ref_bonuses[i] / 100;
						
					uint256	to_payout = users[up].total_deposits.mul(4) - users[up].total_earning;
								
						if(bonus <= to_payout) 
						{
							users[up].match_bonus += bonus;
							users[up].total_earning += bonus;
							users[up].returnRefCount[i] = users[up].returnRefCount[i] +bonus;
							
							
							//users[up].transfer(bonus);
							emit MatchPayout(up, _addr, bonus,10);
						}
						else
						{
							users[up].match_bonus += to_payout;
							users[up].total_earning += to_payout;
							users[up].returnRefCount[i] = users[up].returnRefCount[i] +to_payout;
							//users[up].transfer(to_payout);						
							
							emit MatchPayout(up, _addr, to_payout,10);
						}
					}
				}
			
			}
            up = users[up].upline;
        }
    }

    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = pool_balance / 10;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = draw_amount * pool_bonuses[i] / 100;
			if(users[pool_top[i]].total_earning < users[pool_top[i]].total_deposits.mul(4)) 
			{
				uint256	to_payout = users[pool_top[i]].total_deposits.mul(4) - users[pool_top[i]].total_earning;
								
					if(win <= to_payout) 
					{
						users[pool_top[i]].pool_bonus += win;
						users[pool_top[i]].total_earning += win;
						pool_balance -= win;
						emit PoolPayout(pool_top[i], win);
					}
					else{
						users[pool_top[i]].pool_bonus += to_payout;
						users[pool_top[i]].total_earning += to_payout;
						pool_balance -= to_payout;
						emit PoolPayout(pool_top[i], to_payout);
					}

            
			}
        }
        
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }

    function deposit(address _upline) payable external {
		require(msg.value == 5e8 || msg.value == 1e9 || msg.value == 5e9 || msg.value == 1e10 || msg.value == 25e9 || msg.value == 5e10, "Bad amount");
		
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        require(users[msg.sender].payouts < max_payout, "Full payouts");

        // Deposit payout
        if(to_payout > 0) {
            if(users[msg.sender].payouts + to_payout  > max_payout) {				
                to_payout = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].total_earning +=to_payout;
            users[msg.sender].payouts += to_payout;

            _refPayout(msg.sender, to_payout);
        }
        
        // Direct payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].direct_bonus > 0) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus = max_payout - users[msg.sender].payouts;
				
            }

            users[msg.sender].direct_bonus = 0;
            users[msg.sender].payouts += direct_bonus;
            to_payout += direct_bonus;
        }
        
        // Pool payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].pool_bonus > 0) {
            uint256 pool_bonus = users[msg.sender].pool_bonus;

            if(users[msg.sender].payouts+ pool_bonus > max_payout) {
                pool_bonus = max_payout - users[msg.sender].payouts;
				
            }

            users[msg.sender].pool_bonus = 0;
            users[msg.sender].payouts += pool_bonus;
            to_payout += pool_bonus;
        }

        // Match payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].payouts + match_bonus > max_payout) {
                match_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].match_bonus = 0;
            users[msg.sender].payouts += match_bonus;
            to_payout += match_bonus;
        }
        
        

        require(to_payout > 0, "Zero payout");
        
        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;
		
		uint256 developer = to_payout.mul(10).div(100);
		uint256 total_send= to_payout.sub(developer);

        msg.sender.transfer(total_send);

        emit Withdraw(msg.sender, total_send);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 400 / 100;
    }
    
    
    function timeStamp() view public returns(uint256) {
        return block.timestamp;
    }
    

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf((users[_addr].deposit_amount-paid_deposit[_addr]));
		uint total_payout=users[_addr].direct_bonus+users[_addr].pool_bonus+users[_addr].match_bonus+users[_addr].payouts;
		
        if(total_payout < max_payout) {
		
			if(((users[_addr].deposit_payouts) < max_payout.div(2)))
			{
				payout = ((((users[_addr].deposit_amount-paid_deposit[_addr]) * ((block.timestamp - users[_addr].deposit_time) / 1 days)) / 100)).mul(2)-users[_addr].deposit_payouts;
			}
			if((payout+users[_addr].deposit_payouts)>max_payout.div(2))
			{
			    payout=max_payout.div(2)-users[_addr].deposit_payouts;
			}
            
            if(total_payout + payout > max_payout) {
                payout = max_payout-total_payout;
            }
        }
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
    }
	
	function getUserDownlineCount(address userAddress) public view returns(uint256[] memory) {
		uint256[] memory levelRefCountss = new uint256[](5);
		for(uint8 n=0; n <=4; n++)
		{
		  levelRefCountss[n] = users[userAddress].levelRefCount[n];
		}
		return (levelRefCountss);
	}
	
	function getUserReturnDownlineAmount(address userAddress) public view returns(uint256[] memory) {
		uint256[] memory returnRefCountss = new uint256[](10);
		for(uint8 n=0; n <=9; n++)
		{
		  returnRefCountss[n] = users[userAddress].returnRefCount[n];
		}
		return (returnRefCountss);
	}

    function poolTopInfo() view external returns(address[3] memory addrs, uint256[3] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
}