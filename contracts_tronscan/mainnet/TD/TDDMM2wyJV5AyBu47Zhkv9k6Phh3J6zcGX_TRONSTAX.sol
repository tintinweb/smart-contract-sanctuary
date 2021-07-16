//SourceUnit: TRONSTAX.sol


pragma solidity ^0.5.12;

contract TRONSTAX {
	
	struct UserDeposit {
		uint8 is_completed;
        uint256 amount;
        uint256 totalWithdraw;
        uint256 deposit_payouts;
        uint256 payouts;
        uint256 time;
    }
    struct User {
		bool is_exist;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 pool_bonus;
        uint256 loyalty_pool_bonus;
        uint256 match_bonus;
        UserDeposit[] deposits;
        UserDeposit[] past_deposits;
		uint8 rank;
		uint256 last_deposit;
		uint256 whale;
        uint256 total_sales;
        uint256 total_loyalty_deposits;
        uint256 total_payouts;
    }
	
    address payable public owner;
    address payable public tkn_fund;
    address payable public mtkg_tech;

    mapping(address => User) public users;
	mapping (uint => address) public userList;
	uint public currUserID = 0;
    
    uint8[] public direct_bonuses;
    uint256[] public ranks;
    address[] public userWhales;
    uint16[][] public ref_bonuses;

    uint8[] public pool_bonuses;
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint40 public loyalty_pool_last_draw = uint40(block.timestamp);
    uint40 public start_time = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public loyalty_pool_cycle;
    uint256 public pool_balance;
    uint256 public loyaltypool;
    
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 public total_users = 0;
    uint256 public total_deposited = 0;
    uint256 public total_withdraw = 0;
    uint256 public total_matchbonus = 0;
    uint256 public total_directbonus = 0;
    uint256 public total_loyaltybonus = 0;
	
	uint256 constant LOYALTY_POOL_VAL = 15;
	uint256 constant MTKG_TECH_FUND_VAL = 10;
	uint256 constant TKN_FUND_VAL = 5;
	uint256 constant POOL_BALANCE_VAL = 5;
	uint256 constant POOL_BALANCE_DIST_VAL = 30;
	uint256 constant WITHDRAW_FEE = 5;
	uint256 constant WHALE_POINT = 2e11;
	uint256 constant DAILY_ROI = 125;
	uint256 constant DAILY_ROI_6 = 175;
	uint256 constant ROI_TIMER = 43200;
	uint256 constant MIN_DEPOSIT = 1e8;
	uint256 constant DEPOSIT_LIMIT = 3;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event LoyaltyPoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    
    constructor() public {
        owner = msg.sender;
        
        mtkg_tech = 0x78d926EC2779DedDC9DeA70132d7D2383eA345f2;
        tkn_fund = 0x73007a7D2446C1Fb53a1006BD4cFF8200CcFAaEd;
		
		ranks.push(5e10);
        ranks.push(1e11);
        ranks.push(25e10);
        ranks.push(5e11);
        ranks.push(1e12);
        ranks.push(35e11);
		
        ref_bonuses.push([150, 220, 230, 250, 270, 300, 360]);
        ref_bonuses.push([ 50,  85,  90, 100, 110, 120, 150]);
        ref_bonuses.push([ 50,  85,  90, 100, 110, 120, 150]);
        ref_bonuses.push([ 50,  85,  90, 100, 110, 120, 150]);
        ref_bonuses.push([ 50,  85,  90, 100, 110, 120, 150]);
		
        pool_bonuses.push(35);
        pool_bonuses.push(30);
        pool_bonuses.push(20);
        pool_bonuses.push(10);
        pool_bonuses.push(5);
		
		direct_bonuses.push(100);
        direct_bonuses.push(110);
        direct_bonuses.push(120);
        direct_bonuses.push(130);
        direct_bonuses.push(140);
        direct_bonuses.push(150);
        direct_bonuses.push(160);
		s_upline();
    }

    function() payable external {
        _deposit(msg.sender, msg.value);
    }

    function _setUpline(address _addr, address _upline) private {
		
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposits.length > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;
            emit Upline(_addr, _upline);
            total_users++;
        }
    }
	

    function _deposit(address _addr, uint256 _amount) private {
		
		require(users[_addr].upline != address(0) || _addr == owner, "No upline");

        require(_amount >= MIN_DEPOSIT, "Bad amount");
        require(users[_addr].deposits.length < DEPOSIT_LIMIT, "Deposit Limit Reached");
		
		if(users[_addr].is_exist != true) {
			users[_addr].is_exist = true;
			users[_addr].rank = 0;
			currUserID++;
			userList[currUserID] = _addr;
		}
		users[_addr].deposits.push(UserDeposit({
            is_completed: 0,
            amount: _amount,
            totalWithdraw: 0,
            deposit_payouts: 0,
            payouts: 0,
            time: uint256(block.timestamp)
        }));

		if(users[_addr].last_deposit + 2 days < block.timestamp) {
			users[_addr].total_loyalty_deposits = 0;
		}
        users[_addr].last_deposit = uint256(block.timestamp);
		users[_addr].total_loyalty_deposits = SafeMath.add(users[_addr].total_loyalty_deposits, _amount);
		
		updateWhales(_addr);

        total_deposited = SafeMath.add(total_deposited, _amount);
        
        emit NewDeposit(_addr, _amount);

        if(users[_addr].upline != address(0)) {
			uint256 directbonus 		=	SafeMath.mul(_amount , direct_bonuses[users[users[_addr].upline].rank]);
            total_directbonus 			= 	SafeMath.add(total_directbonus, SafeMath.add(users[users[_addr].upline].direct_bonus, SafeMath.div(directbonus,1000)));
            users[users[_addr].upline].direct_bonus = SafeMath.add(users[users[_addr].upline].direct_bonus, SafeMath.div(directbonus,1000));
			users[users[_addr].upline].total_sales 	= SafeMath.add(users[users[_addr].upline].total_sales, _amount);
			updaterank(users[_addr].upline);
            emit DirectPayout(users[_addr].upline, _addr, directbonus);
        }
        
        if(pool_last_draw + 7 days < block.timestamp) {
            _drawPool();
        }
		
		if(loyalty_pool_last_draw + 2 days < block.timestamp) {
            _loyalty_drawPool();
        }
        _poolDeposits(_addr, _amount);
		
		loyaltypool	=	SafeMath.add(loyaltypool, SafeMath.div(SafeMath.mul(_amount, LOYALTY_POOL_VAL), 1000));
		
		mtkg_tech.transfer(SafeMath.div(SafeMath.mul(_amount, MTKG_TECH_FUND_VAL), 100));
		tkn_fund.transfer(SafeMath.div(SafeMath.mul(_amount, TKN_FUND_VAL), 100));
    }
	
	
	function updaterank(address _addr) private {
		
		if(users[_addr].rank<6){
			if(users[_addr].total_sales>= ranks[5]){
				users[_addr].rank 	=	6;
			}else if(users[_addr].total_sales>= ranks[4]){
				users[_addr].rank 	=	5;
			}else if(users[_addr].total_sales>= ranks[3]){
				users[_addr].rank 	=	4;
			}else if(users[_addr].total_sales>= ranks[2]){
				users[_addr].rank 	=	3;
			}else if(users[_addr].total_sales>= ranks[1]){
				users[_addr].rank 	=	2;
			}else if(users[_addr].total_sales>= ranks[0]){
				users[_addr].rank 	=	1;
			}
		}
	}
	
	function updateWhales(address _addr) private {
		
		if(users[_addr].total_loyalty_deposits >= WHALE_POINT){ 
			if(users[_addr].whale==0){
				userWhales.push(_addr);
			}
			users[_addr].whale	=	(uint256) (users[_addr].total_loyalty_deposits/WHALE_POINT);
		}
	}

    function _poolDeposits(address _addr, uint256 _amount) private {
		
        pool_balance = SafeMath.add(pool_balance, SafeMath.div(SafeMath.mul(_amount, POOL_BALANCE_VAL), 100));

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

    function s_upline() private {
		users[msg.sender].is_exist = true;
		users[msg.sender].rank 		= 0;
		currUserID++;
		userList[currUserID] = msg.sender;
	}
	
    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(users[up].referrals >= i + 1) {
                uint256 bonus 			= 	SafeMath.div(SafeMath.mul(_amount, ref_bonuses[i][users[up].rank]), 1000);
				users[up].match_bonus 	= 	SafeMath.add(users[up].match_bonus, bonus);
				total_matchbonus 		= 	SafeMath.add(total_matchbonus, bonus);
				emit MatchPayout(up, _addr, bonus);
            }
            up = users[up].upline;
        }
    }

    function _drawPool() private {
		
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = SafeMath.div(SafeMath.mul(pool_balance, POOL_BALANCE_DIST_VAL) , 100);

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = SafeMath.div(SafeMath.mul(draw_amount, pool_bonuses[i]), 100);

            users[pool_top[i]].pool_bonus = SafeMath.add(users[pool_top[i]].pool_bonus, win);
            pool_balance = SafeMath.sub(pool_balance, win);

            emit PoolPayout(pool_top[i], win);
        }
        
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }
	
	function _loyalty_drawPool() private {
		
		loyalty_pool_cycle++;
		loyalty_pool_last_draw = uint40(block.timestamp);
		if(userWhales.length>0){
			
			uint256 totalloyaltypoolwhale	=	0;
			
			for(uint8 i = 0; i < userWhales.length; i++) {
				totalloyaltypoolwhale	+=	users[userWhales[i]].whale;
			}
			for(uint8 i = 0; i < userWhales.length; i++) {
				if(userWhales[i] == address(0)) break;
				
				uint256 userWhale 	=	(uint256) (users[userWhales[i]].whale);

				uint256 win = SafeMath.div(loyaltypool, totalloyaltypoolwhale);

				total_loyaltybonus = SafeMath.add(total_loyaltybonus, SafeMath.add(users[userWhales[i]].loyalty_pool_bonus, win * userWhale));
				users[userWhales[i]].loyalty_pool_bonus = SafeMath.add(users[userWhales[i]].loyalty_pool_bonus, win * userWhale);
				users[userWhales[i]].whale					=	0;
				users[userWhales[i]].total_loyalty_deposits	=	0;
				emit LoyaltyPoolPayout(userWhales[i], win * userWhale);
			}
			loyaltypool				=	0;
			userWhales.length		=	0;
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
		
        (uint256 withdraw_payout, ) = updatepayoutOf(msg.sender);

        require(withdraw_payout > 0, "Zero payout");
		
		uint256 withdrawFee	=	SafeMath.div(SafeMath.mul(withdraw_payout, WITHDRAW_FEE),100);
		if(getBalance() < withdraw_payout){
			withdraw_payout 	=	getBalance();
			withdrawFee			=	0;
		}
	
		users[msg.sender].total_payouts = SafeMath.add(users[msg.sender].total_payouts, withdraw_payout);
		total_withdraw = SafeMath.add(total_withdraw, withdraw_payout);
			
		msg.sender.transfer(SafeMath.sub(withdraw_payout, withdrawFee));

		emit Withdraw(msg.sender, SafeMath.sub(withdraw_payout, withdrawFee));
    }
	
	function reinvest() external {
		
        (uint256 withdraw_payout, ) = updatepayoutOf(msg.sender);

        require(withdraw_payout > 0, "Zero payout");
		
		users[msg.sender].total_payouts = SafeMath.add(users[msg.sender].total_payouts, withdraw_payout);
		total_withdraw = SafeMath.add(total_withdraw, withdraw_payout);
		
		_deposit(msg.sender, withdraw_payout);
		emit Withdraw(msg.sender, withdraw_payout);
    }
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return SafeMath.mul(_amount, 2);
    }
	
	
	function updatepayoutOf(address _addr) private returns(uint256 withdraw_payout, uint256 total_payout) {
		
		withdraw_payout			=	0;
		uint256 check_completed	=	0;
		for(uint256 i = 0; i < users[_addr].deposits.length; i++) {
            
			uint256 max_payout = this.maxPayoutOf(users[_addr].deposits[i].amount);
		
			if(users[_addr].deposits[i].is_completed==0) {
				uint256 to_payout	=	0;
				if(users[_addr].rank==6){
					
					to_payout = SafeMath.sub(SafeMath.div(SafeMath.mul(SafeMath.mul(users[_addr].deposits[i].amount, ((block.timestamp - users[_addr].deposits[i].time) / ROI_TIMER)), DAILY_ROI_6), 20000), users[_addr].deposits[i].deposit_payouts);	
				}else{
					to_payout = SafeMath.sub(SafeMath.div(SafeMath.mul(SafeMath.mul(users[_addr].deposits[i].amount, ((block.timestamp - users[_addr].deposits[i].time) / ROI_TIMER)), DAILY_ROI), 20000), users[_addr].deposits[i].deposit_payouts);
				}
				
				if(to_payout > 0) {
					
					if(SafeMath.add(users[_addr].deposits[i].payouts, to_payout) > max_payout) {
						to_payout = SafeMath.sub(max_payout, users[_addr].deposits[i].payouts);
						users[_addr].deposits[i].is_completed	=	1;
						check_completed++;
					}
					users[_addr].deposits[i].deposit_payouts = SafeMath.add(users[_addr].deposits[i].deposit_payouts, to_payout);
					users[_addr].deposits[i].payouts = SafeMath.add(users[_addr].deposits[i].payouts, to_payout); 
					users[_addr].payouts = SafeMath.add(users[_addr].payouts, to_payout);
					total_payout								=	SafeMath.add(total_payout, to_payout); 
				}
				
				if(users[_addr].deposits[i].payouts < max_payout && users[_addr].direct_bonus > 0) { 
					uint256 direct_bonus = users[_addr].direct_bonus;
					
					if(SafeMath.add(users[_addr].deposits[i].payouts,  direct_bonus) > max_payout) { 
						direct_bonus = SafeMath.sub(max_payout, users[_addr].deposits[i].payouts); 
						users[_addr].deposits[i].is_completed	=	1;
						check_completed++;
					}
					users[_addr].direct_bonus = SafeMath.sub(users[_addr].direct_bonus, direct_bonus);
					users[_addr].deposits[i].payouts = SafeMath.add(users[_addr].deposits[i].payouts, direct_bonus);
					users[_addr].payouts = SafeMath.add(users[_addr].payouts, direct_bonus);
					to_payout = SafeMath.add(to_payout, direct_bonus);
				}
				
				if(users[_addr].deposits[i].payouts < max_payout && users[_addr].pool_bonus > 0) {
					uint256 pool_bonus = users[_addr].pool_bonus;

					if(SafeMath.add(users[_addr].deposits[i].payouts,  pool_bonus) > max_payout) {
						pool_bonus = SafeMath.sub(max_payout , users[_addr].deposits[i].payouts);
						users[_addr].deposits[i].is_completed	=	1;
						check_completed++;
					}

					users[_addr].pool_bonus = SafeMath.sub(users[_addr].pool_bonus, pool_bonus);
					users[_addr].deposits[i].payouts = SafeMath.add(users[_addr].deposits[i].payouts, pool_bonus);
					users[_addr].payouts = SafeMath.add(users[_addr].payouts, pool_bonus);
					to_payout = SafeMath.add(to_payout, pool_bonus);
				}
				
				if(users[_addr].deposits[i].payouts < max_payout && users[_addr].loyalty_pool_bonus > 0) {
					uint256 loyalty_pool_bonus = users[_addr].loyalty_pool_bonus;

					if(SafeMath.add(users[_addr].deposits[i].payouts,  loyalty_pool_bonus) > max_payout) {
						loyalty_pool_bonus = SafeMath.sub(max_payout, users[_addr].deposits[i].payouts);
						users[_addr].deposits[i].is_completed	=	1;
						check_completed++;
					}

					users[_addr].loyalty_pool_bonus = SafeMath.sub(users[_addr].loyalty_pool_bonus, loyalty_pool_bonus);
					users[_addr].deposits[i].payouts = SafeMath.add(users[_addr].deposits[i].payouts, loyalty_pool_bonus);
					users[_addr].payouts = SafeMath.add(users[_addr].payouts, loyalty_pool_bonus);
					to_payout = SafeMath.add(to_payout, loyalty_pool_bonus);
				}

				if(users[_addr].deposits[i].payouts < max_payout && users[_addr].match_bonus > 0) {
					uint256 match_bonus = users[_addr].match_bonus;

					if(SafeMath.add(users[_addr].deposits[i].payouts,  match_bonus) > max_payout) {
						match_bonus = SafeMath.sub(max_payout, users[_addr].deposits[i].payouts);
						users[_addr].deposits[i].is_completed	=	1;
						check_completed++;
					}

					users[_addr].match_bonus = SafeMath.sub(users[_addr].match_bonus, match_bonus);
					users[_addr].deposits[i].payouts = SafeMath.add(users[_addr].deposits[i].payouts, match_bonus);
					users[_addr].payouts = SafeMath.add(users[_addr].payouts, match_bonus);
					to_payout = SafeMath.add(to_payout, match_bonus);
				}
				withdraw_payout	=	SafeMath.add(withdraw_payout, to_payout);
			}
		}
		if(total_payout>0){
			_refPayout(_addr, total_payout);
		}
		if(check_completed > 0){
			shiftCompleted(_addr);
		}
    }

	function shiftCompleted(address _addr) private {

		UserDeposit[] memory current_deposits	=	users[_addr].deposits;
		users[_addr].deposits.length	=	0;
		for(uint256 i = 0; i < current_deposits.length; i++) {
			if(current_deposits[i].is_completed==0) {
				users[_addr].deposits.push(UserDeposit({
					is_completed: current_deposits[i].is_completed,
					amount: current_deposits[i].amount,
					totalWithdraw: current_deposits[i].totalWithdraw,
					deposit_payouts: current_deposits[i].deposit_payouts,
					payouts: current_deposits[i].payouts,
					time: current_deposits[i].time
				}));
			}else{
				users[_addr].past_deposits.push(UserDeposit({
					is_completed: current_deposits[i].is_completed,
					amount: current_deposits[i].amount,
					totalWithdraw: current_deposits[i].totalWithdraw,
					deposit_payouts: current_deposits[i].deposit_payouts,
					payouts: current_deposits[i].payouts,
					time: current_deposits[i].time
				}));
			}
		}
	}

    function payoutOf(address _addr) view external returns(uint256 withdraw_payout, uint256 total_payout) {
		
		withdraw_payout	=	0;
		total_payout	=	0;
		for(uint256 i = 0; i < users[_addr].deposits.length; i++) {
            
			uint256 max_payout = this.maxPayoutOf(users[_addr].deposits[i].amount);
		
			if(users[_addr].deposits[i].is_completed==0) {
				uint256 to_payout	=	0;
				if(users[_addr].rank==6){
					to_payout = SafeMath.sub(SafeMath.div(SafeMath.mul(SafeMath.mul(users[_addr].deposits[i].amount, ((block.timestamp - users[_addr].deposits[i].time) / ROI_TIMER)), DAILY_ROI_6), 20000), users[_addr].deposits[i].deposit_payouts);	
				}else{
					to_payout = SafeMath.sub(SafeMath.div(SafeMath.mul(SafeMath.mul(users[_addr].deposits[i].amount, ((block.timestamp - users[_addr].deposits[i].time) / ROI_TIMER)), DAILY_ROI), 20000), users[_addr].deposits[i].deposit_payouts);
				}
				
				if(to_payout > 0) {
					
					if(SafeMath.add(users[_addr].deposits[i].payouts, to_payout) > max_payout) {
						to_payout = SafeMath.sub(max_payout, users[_addr].deposits[i].payouts);
					}
					total_payout								=	SafeMath.add(total_payout, to_payout); 
				}
				
				if(SafeMath.add(users[_addr].deposits[i].payouts, to_payout) < max_payout && users[_addr].direct_bonus > 0) {
					uint256 direct_bonus = users[_addr].direct_bonus;
					
					if(SafeMath.add(users[_addr].deposits[i].payouts,  SafeMath.add(to_payout, direct_bonus)) > max_payout) {
						direct_bonus = SafeMath.sub(max_payout, SafeMath.add(users[_addr].deposits[i].payouts, to_payout)); 
					}
					
					to_payout = SafeMath.add(to_payout, direct_bonus); 
				}
				 
				
				if(SafeMath.add(users[_addr].deposits[i].payouts, to_payout) < max_payout && users[_addr].pool_bonus > 0) {
					uint256 pool_bonus = users[_addr].pool_bonus;

					if(SafeMath.add(users[_addr].deposits[i].payouts,  SafeMath.add(to_payout, pool_bonus)) > max_payout) {
						pool_bonus = SafeMath.sub(max_payout, SafeMath.add(users[_addr].deposits[i].payouts, to_payout));
					}
					to_payout = SafeMath.add(to_payout, pool_bonus);
				}
				
				if(SafeMath.add(users[_addr].deposits[i].payouts, to_payout) < max_payout && users[_addr].loyalty_pool_bonus > 0) {
					uint256 loyalty_pool_bonus = users[_addr].loyalty_pool_bonus;

					if(SafeMath.add(users[_addr].deposits[i].payouts,  SafeMath.add(to_payout, loyalty_pool_bonus)) > max_payout) {
						loyalty_pool_bonus = SafeMath.sub(max_payout, SafeMath.add(users[_addr].deposits[i].payouts, to_payout));
					}

					to_payout = SafeMath.add(to_payout, loyalty_pool_bonus);
				}

				if(SafeMath.add(users[_addr].deposits[i].payouts, to_payout) < max_payout && users[_addr].match_bonus > 0) {
					uint256 match_bonus = users[_addr].match_bonus;

					if(SafeMath.add(users[_addr].deposits[i].payouts,  SafeMath.add(to_payout, match_bonus)) > max_payout) {
						match_bonus = SafeMath.sub(max_payout, SafeMath.add(users[_addr].deposits[i].payouts, to_payout));
					}
					to_payout = SafeMath.add(to_payout, match_bonus);
				}
				withdraw_payout	=	SafeMath.add(withdraw_payout, to_payout); 
			}
		}
    }
	
	function getAllInfo(address _addr) view external returns(
		address upline,
		uint8 rank,
		uint256 whale,
		uint256[25] memory bonuses,
		uint40 _pool_last_draw,
		address[5] memory pool_top_address, 
		uint256[5] memory pool_top_sales,
		uint256[5] memory pool_user_bonuses
	) 
	{
		uint256 draw_amount = SafeMath.div(SafeMath.mul(pool_balance, POOL_BALANCE_DIST_VAL) , 100);

		(uint256 withdraw_payout, uint256 total_payout) = this.payoutOf(_addr);
		for(uint8 i = 0; i < pool_bonuses.length; i++) {
			
            if(pool_top[i] == address(0)) break;
            pool_top_address[i] = pool_top[i];
            pool_top_sales[i] 	= pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
			uint256 win = SafeMath.div(SafeMath.mul(draw_amount, pool_bonuses[i]), 100);
            pool_user_bonuses[i] = win;
        }
		
		bonuses[0]	=	users[_addr].payouts;
		bonuses[1]	=	users[_addr].direct_bonus;
		bonuses[2]	=	users[_addr].pool_bonus;
		bonuses[3]	=	users[_addr].loyalty_pool_bonus;
		bonuses[4]	=	users[_addr].match_bonus;
		bonuses[5]	=	withdraw_payout;
		bonuses[6]	=	total_payout;
		bonuses[7]	=	users[_addr].referrals;
		bonuses[8]	=	users[_addr].total_sales;
		bonuses[9]	=	users[_addr].total_payouts;
		bonuses[10]	=	total_users;
		bonuses[11]	=	total_withdraw;
		bonuses[12]	=	pool_balance;
		bonuses[13]	=	getBalance();
		bonuses[14]	=	address(_addr).balance;
		bonuses[15]	=	total_matchbonus;
		bonuses[16]	=	total_directbonus;
		bonuses[17]	=	total_loyaltybonus;
		bonuses[18]	=	loyalty_pool_last_draw;
		bonuses[19]	=	loyalty_pool_last_draw + 2 days;
		bonuses[20]	=	pool_last_draw + 7 days;
		bonuses[21]	=	users[_addr].total_loyalty_deposits;
		bonuses[22]	=	loyaltypool;
		bonuses[23]	=	users[_addr].last_deposit;
		bonuses[24]	=	total_deposited;
		
		return (
				users[_addr].upline,
				users[_addr].rank,
				users[_addr].whale,
				bonuses,
				pool_last_draw, 
				pool_top_address,
				pool_top_sales,
				pool_user_bonuses
			);	
	}
	
	function getMyActiveDepositsInfo(address _addr) view external returns(
		uint8[] memory mydepositsstatus,
		uint256[] memory mydeposits,
		uint256[] memory mydepositstimes,
		uint256[] memory mydepositsdpayouts,
		uint256[] memory mydepositswithdrans,
		uint256[] memory mydepositspayouts
	) 
	{
		uint8[] memory _mydepositsstatus 		= 	new uint8[](users[_addr].deposits.length);
		uint256[] memory _mydeposits 			= 	new uint256[](users[_addr].deposits.length);
		uint256[] memory _mydepositstimes 		= 	new uint256[](users[_addr].deposits.length);
		uint256[] memory _mydepositsdpayouts 	= 	new uint256[](users[_addr].deposits.length);
		uint256[] memory _mydepositswithdrans 	= 	new uint256[](users[_addr].deposits.length);
		uint256[] memory _mydepositspayouts 	= 	new uint256[](users[_addr].deposits.length);
		
		for(uint256 i = 0; i < users[_addr].deposits.length; i++) {
			_mydepositsstatus[i] 		= users[_addr].deposits[i].is_completed;
			_mydeposits[i] 				= users[_addr].deposits[i].amount;
			_mydepositstimes[i] 		= users[_addr].deposits[i].time;
			_mydepositsdpayouts[i] 		= users[_addr].deposits[i].deposit_payouts;
			_mydepositswithdrans[i] 	= users[_addr].deposits[i].totalWithdraw;
			_mydepositspayouts[i] 		= users[_addr].deposits[i].payouts;
		}
		
		return (
				_mydepositsstatus,
				_mydeposits,
				_mydepositstimes,
				_mydepositsdpayouts,
				_mydepositswithdrans,
				_mydepositspayouts
			);
	}

	function getMyPastDepositsInfo(address _addr) view external returns(
		uint8[] memory mypastdepositsstatus,
		uint256[] memory mypastdeposits,
		uint256[] memory mypastdepositstimes,
		uint256[] memory mypastdepositsdpayouts,
		uint256[] memory mypastdepositswithdrans,
		uint256[] memory mypastdepositspayouts
	) 
	{
		uint8[] memory _mypastdepositsstatus 		= 	new uint8[](users[_addr].past_deposits.length);
		uint256[] memory _mypastdeposits 			= 	new uint256[](users[_addr].past_deposits.length);
		uint256[] memory _mypastdepositstimes 		= 	new uint256[](users[_addr].past_deposits.length);
		uint256[] memory _mypastdepositsdpayouts 	= 	new uint256[](users[_addr].past_deposits.length);
		uint256[] memory _mypastdepositswithdrans 	= 	new uint256[](users[_addr].past_deposits.length);
		uint256[] memory _mypastdepositspayouts 	= 	new uint256[](users[_addr].past_deposits.length);
		
		for(uint256 i = 0; i < users[_addr].past_deposits.length; i++) {
			_mypastdepositsstatus[i] 				= 	users[_addr].past_deposits[i].is_completed;
			_mypastdeposits[i] 						= 	users[_addr].past_deposits[i].amount;
			_mypastdepositstimes[i] 				= 	users[_addr].past_deposits[i].time;
			_mypastdepositsdpayouts[i] 				= 	users[_addr].past_deposits[i].deposit_payouts;
			_mypastdepositswithdrans[i] 			= 	users[_addr].past_deposits[i].totalWithdraw;
			_mypastdepositspayouts[i] 				= 	users[_addr].past_deposits[i].payouts;
		}

		
		return (
				_mypastdepositsstatus,
				_mypastdeposits,
				_mypastdepositstimes,
				_mypastdepositsdpayouts,
				_mypastdepositswithdrans,
				_mypastdepositspayouts
			);
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