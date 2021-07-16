//SourceUnit: TX365Main-For-Test-updated.sol

/*
Website: https://tx365.io/
*/

pragma solidity ^0.5.12;

contract TX365 {
    struct User {
		bool is_exist;
		uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
    }

    address payable public owner;
    address payable public dev_fund;
    address payable public mkt_fund;
    address payable public tokenDividend;

    mapping(address => User) public users;
	mapping (uint => address) public userList;
	uint public currUserID = 0;
    uint256[] public cycles;
    uint8[] public ref_bonuses;

    uint8[] public pool_bonuses;
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    uint256 public insurance_pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    event UsernameChanged(address indexed addr);

    constructor() public {
        owner = msg.sender;
        
        dev_fund = 0xE85aD708Bf23CE796Fe2bd8B668280880Ce6e83d;
        mkt_fund = 0xC65dBd007685114181418085162e8543409d51C6;
        tokenDividend = 0xC3EeC625a82471ffB6735B1F478A47691B8Fc488;
		
        
        ref_bonuses.push(31);
        ref_bonuses.push(11);
        ref_bonuses.push(11);
        ref_bonuses.push(11);
        ref_bonuses.push(11);
        ref_bonuses.push(9);
        ref_bonuses.push(9);
        ref_bonuses.push(9);
        ref_bonuses.push(9);
        ref_bonuses.push(9);
        ref_bonuses.push(6);
        ref_bonuses.push(6);
        ref_bonuses.push(6);
        ref_bonuses.push(6);
        ref_bonuses.push(6);

        pool_bonuses.push(35);
        pool_bonuses.push(30);
        pool_bonuses.push(20);
        pool_bonuses.push(10);
        pool_bonuses.push(5);

        cycles.push(5e10);
        cycles.push(2e11);
        cycles.push(6e11);
        cycles.push(18e11);
        cycles.push(365e11);
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

    function _deposit(address _addr, uint256 _amount) private {
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
			
            require(_amount >= users[_addr].deposit_amount && _amount <= cycles[users[_addr].cycle > cycles.length - 1 ? cycles.length - 1 : users[_addr].cycle], "Bad amount");
        }
        else require(_amount >= 5e6 && _amount <= cycles[0], "Bad amount");
		
		if(users[_addr].is_exist != true) {
			users[_addr].is_exist = true;
			currUserID++;
			userList[currUserID] = _addr;
		}
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits = SafeMath.add(users[_addr].total_deposits, _amount);

        total_deposited = SafeMath.add(total_deposited, _amount);
        
        emit NewDeposit(_addr, _amount);

        if(users[_addr].upline != address(0)) {
			uint256 directbonus 	=	SafeMath.div(_amount , 10);
            users[users[_addr].upline].direct_bonus = SafeMath.add(users[users[_addr].upline].direct_bonus, directbonus);

            emit DirectPayout(users[_addr].upline, _addr, directbonus);
        }

        _poolDeposits(_addr, _amount);
        
        insurance_pool_balance = SafeMath.add(insurance_pool_balance, SafeMath.div(SafeMath.mul(_amount , 5) , 100));

        if(pool_last_draw + 7 days < block.timestamp) {
            _drawPool();
        }

        mkt_fund.transfer(SafeMath.div(SafeMath.mul(_amount , 6) , 100));
        dev_fund.transfer(SafeMath.div(SafeMath.mul(_amount , 4) , 100));
		
		uint amounttokens 	=	SafeMath.div(SafeMath.mul(_amount , 5) , 100);
		(bool success,  ) = tokenDividend.call.value(amounttokens)(toBytes(_addr));
		require(success, "Contract execution Failed");
		
    }

    function _poolDeposits(address _addr, uint256 _amount) private {
		
        pool_balance = SafeMath.add(pool_balance, SafeMath.div(SafeMath.mul(_amount , 5) , 100));

        address upline = users[_addr].upline;

        if(upline == address(0)) return;
        
        pool_users_refs_deposits_sum[pool_cycle][upline] = SafeMath.add(pool_users_refs_deposits_sum[pool_cycle][upline], _amount);

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
            
            if(users[up].referrals >= i + 1) {
                uint256 bonus = SafeMath.div(SafeMath.mul(_amount , ref_bonuses[i]) , 100);
                
                users[up].match_bonus = SafeMath.add(users[up].match_bonus, bonus);

                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }

    function _drawPool() private {
		
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = SafeMath.div(SafeMath.mul(pool_balance , 30) , 100);

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = SafeMath.div(SafeMath.mul(draw_amount , pool_bonuses[i]) , 100);

            users[pool_top[i]].pool_bonus = SafeMath.add(users[pool_top[i]].pool_bonus, win);
            pool_balance = SafeMath.sub(pool_balance, win);

            emit PoolPayout(pool_top[i], win);
        }
        
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }

    function deposit(address _upline) payable external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }
	
	function createAccount(address _user, address _upline) payable external {
        _setUpline(_user, _upline);
        _deposit(_user, msg.value);
    }

    function withdraw() external {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        
        require(users[msg.sender].payouts < max_payout, "Full payouts");

        if(to_payout > 0) {
            if(users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = SafeMath.sub(max_payout , users[msg.sender].payouts);
            }

            users[msg.sender].deposit_payouts = SafeMath.add(users[msg.sender].deposit_payouts, to_payout);
            users[msg.sender].payouts = SafeMath.add(users[msg.sender].payouts, to_payout);

            _refPayout(msg.sender, to_payout);
        }
        
        if(users[msg.sender].payouts < max_payout && users[msg.sender].direct_bonus > 0) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus = SafeMath.sub(max_payout , users[msg.sender].payouts);
            }

            users[msg.sender].direct_bonus = SafeMath.sub(users[msg.sender].direct_bonus , direct_bonus);
            users[msg.sender].payouts = SafeMath.add(users[msg.sender].payouts, direct_bonus);
            to_payout = SafeMath.add(to_payout, direct_bonus);
        }
        
        if(users[msg.sender].payouts < max_payout && users[msg.sender].pool_bonus > 0) {
            uint256 pool_bonus = users[msg.sender].pool_bonus;

            if(users[msg.sender].payouts + pool_bonus > max_payout) {
				pool_bonus = SafeMath.sub(max_payout , users[msg.sender].payouts);
            }

            users[msg.sender].pool_bonus = SafeMath.sub(users[msg.sender].pool_bonus , pool_bonus);
            users[msg.sender].payouts = SafeMath.add(users[msg.sender].payouts, pool_bonus);
            to_payout = SafeMath.add(to_payout, pool_bonus);
        }

        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].payouts + match_bonus > max_payout) {
                match_bonus = SafeMath.sub(max_payout, users[msg.sender].payouts);
            }

            users[msg.sender].match_bonus = SafeMath.sub(users[msg.sender].match_bonus, match_bonus);
            users[msg.sender].payouts = SafeMath.add(users[msg.sender].payouts, match_bonus);
            to_payout = SafeMath.add(to_payout, match_bonus);
        }

        require(to_payout > 0, "Zero payout");
        uint256 effectiveBalance	=	0;
		if(getBalance() > to_payout){
			effectiveBalance 	=	SafeMath.sub(getBalance() , to_payout);
		}else{
			effectiveBalance 	=	getBalance();
		}
		
		if(effectiveBalance > 0 && effectiveBalance > insurance_pool_balance){
	
			users[msg.sender].total_payouts = SafeMath.add(users[msg.sender].total_payouts, to_payout);
			total_withdraw = SafeMath.add(total_withdraw, to_payout);
			if(getBalance() > to_payout){
				msg.sender.transfer(to_payout);

				emit Withdraw(msg.sender, to_payout);

				if(users[msg.sender].payouts >= max_payout) {
					emit LimitReached(msg.sender, users[msg.sender].payouts);
				}
			}
		}else{
			
			
			uint256 effectivePayout	=	0;
			if(getBalance() > insurance_pool_balance){
				effectivePayout 	=	SafeMath.sub(getBalance() , insurance_pool_balance); 
			}else{
				effectivePayout 	=	0;
			}
			if(effectivePayout>0){
				users[msg.sender].total_payouts = SafeMath.add(users[msg.sender].total_payouts, effectivePayout);
				total_withdraw = SafeMath.add(total_withdraw, effectivePayout);
				
				msg.sender.transfer(effectivePayout);

				emit Withdraw(msg.sender, effectivePayout);

				if(users[msg.sender].payouts >= max_payout) {
					emit LimitReached(msg.sender, users[msg.sender].payouts);
				}
			}
			_distributeInsurance();
		}
    }
	
	function _distributeInsurance() internal{
		mkt_fund.transfer(SafeMath.div(SafeMath.mul(insurance_pool_balance , 20) , 100));
		
		dev_fund.transfer(SafeMath.div(SafeMath.mul(insurance_pool_balance , 15) , 100));
		
		uint lastUserId 			=	currUserID;
		uint amountosend 			=	0;
		
		for(uint j=1; j<=50; j++){
			
			if(lastUserId>0){
				if(j==1){
					amountosend	=	(SafeMath.div(SafeMath.mul(insurance_pool_balance , 20) , 100));
				}else if(j==2){
					amountosend	=	(SafeMath.div(SafeMath.mul(insurance_pool_balance , 15) , 100));
				}else if(j==3){
					amountosend	=	(SafeMath.div(SafeMath.mul(insurance_pool_balance , 10) , 100));
				}else if(j==4){
					amountosend	=	(SafeMath.div(SafeMath.mul(insurance_pool_balance , 1) , 100));
				}else if(j==5){
					amountosend	=	(SafeMath.div(SafeMath.mul(insurance_pool_balance , 1) , 100));
				}else{
					amountosend	=	(SafeMath.div(SafeMath.mul(insurance_pool_balance , 5) , 1000));
				}
				address lastUserAddress 	=	userList[lastUserId];
				if(lastUserAddress == address(0)) {
					mkt_fund.transfer(amountosend);
				}else{
					address(uint160(lastUserAddress)).transfer(amountosend);
				}
			}
			lastUserId--;
		}
		insurance_pool_balance	=	0;
	}
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return (SafeMath.div(SafeMath.mul(_amount , 365) , 100));
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {
			
            payout = SafeMath.sub(SafeMath.div(SafeMath.mul(SafeMath.mul(users[_addr].deposit_amount , ((block.timestamp - users[_addr].deposit_time) / 43200)), 11),2000), users[_addr].deposit_payouts);
            
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = SafeMath.sub(max_payout , users[_addr].deposit_payouts);
            }
        }
    }

    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus) {
		
		return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure, uint256 total_payout) {
		(uint256 to_payout, uint256 max_payout) = this.payoutOf(_addr);
		uint256 user_total_payout	=	SafeMath.add(SafeMath.add(SafeMath.add(users[_addr].direct_bonus, users[_addr].pool_bonus), users[_addr].match_bonus) , to_payout);
		
		if(max_payout < user_total_payout){
			user_total_payout	=	max_payout;
		}
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure, user_total_payout);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
    }

    function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
	
    function getBalance() public view returns(uint) {
		return address(this).balance;
    }
	
	function toBytes(address x) public view returns (bytes memory b) {
		b = new bytes(20);
		for (uint i = 0; i < 20; i++)
			b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
	}
}



library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}