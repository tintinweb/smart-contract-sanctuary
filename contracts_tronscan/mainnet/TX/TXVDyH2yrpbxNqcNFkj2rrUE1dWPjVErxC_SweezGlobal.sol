//SourceUnit: SweezGlobal.sol

pragma solidity 0.5.4;

contract SweezGlobal {

    struct User { 
        uint256 userid;
        address upline ;
        uint256 referrals ;
        uint256 payouts ;
        uint256 direct_bonus ;
        uint256 gen_bonus ;
        uint256 pool_bonus ;
        uint256 deposit_amount ;
        uint256 deposit_payouts ;
        uint40 deposit_time ; 
        uint256 wonder_directs;
		uint256 wonder_bonus ;
        uint256 isActive ;
	    uint256 total_business ;
     } 

    struct UserTotal {
        uint256 total_deposits ;
        uint256 total_payouts ;
        uint256 total_structure ;
        uint256 wonder_time;
        bool shareHolder;
        bool coFounder;
     } 

     struct User2 {
         address upline ;
         uint256 whale_bonus ;
         uint256 active_directs ;
		 uint256 active_bonus ;
		 uint256 active_deposits ;
      } 
    
    uint256 constant public CONTRACT_BALANCE_STEP = 500000 trx ; // 1000000 trx
    uint256 constant public MIN_DEPOSIT = 100 trx ; // 100 trx
    uint256 constant public wonder_period = 7 days ; // 7 days 
    uint256 constant public active_period = 1 days ; // 1 days 
    uint256 constant public active_directs1 = 7 ; // 7 directs 
    uint256 constant public active_directs2 = 15 ; // 15 directs 
    uint256 constant public active_directs3 = 30 ; // 30 directs 
    uint256 constant public aff_bonus = 10 ; // 10 percent
    uint256 public shareHolder_value = 5000 trx ;
    uint256 public coFounder_value = 50000 trx ;
    uint256 constant public pool_period = 1 days; // 1 days  
    uint256 constant public wonder_min_deposit = 1000 trx; //  

    // uint256 constant public CONTRACT_BALANCE_STEP = 50 trx ; // 500000 trx
    // uint256 constant public MIN_DEPOSIT = 10 trx ; // 100 trx
    // uint256 constant public wonder_period = 3600 ; // 7 days 
    // uint256 constant public active_period = 3600 ; // 7 days 
    // uint256 constant public active_directs1 = 3 ; // 7 days 
    // uint256 constant public active_directs2 = 5 ; // 7 days 
    // uint256 constant public active_directs3 = 7 ; // 7 days 
    // uint256 constant public aff_bonus = 10 ; // 10 percent
    // uint256 public shareHolder_value = 50 trx ;
    // uint256 public coFounder_value = 500 trx ;
    // uint256 constant public pool_period = 3600 ; // 1 days 
    // uint256 constant public wonder_min_deposit = 50 trx; // 100 trx   

    uint256 constant public admin_fee1  = 50 ;   
    uint256 constant public admin_fee2  = 30 ;   

    uint256 constant public BASE_PERCENT = 230 ; // 2.3% daily
    // uint256 constant public baseSecRate = 266204 ;  // 2.3% daily
    // uint256 constant public incSecRate = 11575 ;  // 0.1% daily
    uint256 constant public million = 1000000 ;  // 6 zeros
    uint256 constant public mainDivider = million*million ;  //12 zeros
 
    //pool bonus
    uint8[] public pool_bonuses ;                            // 7%
    uint8[] public whale_bonuses ;                            // 3%
    uint40 public pool_last_draw = uint40(block.timestamp) ;
    uint256 public pool_cycle ;
    uint256 public pool_balance ;
    uint256 public whale_balance ;

    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum ;
    mapping(uint8 => address) public pool_top ;
    mapping(address => bool) public top_promoters;
    
    mapping(uint256 => mapping(address => uint256)) public whale_users_deposits ;
    mapping(uint8 => address) public whale_top ;
    mapping(address => bool) public top_whales;
    
    mapping(address => User) public users ;
    mapping(address => User2) public users2 ;
    mapping(address => UserTotal) public usertotals ;
    mapping(uint256 => address) public ids ;

    uint8[] public ref_bonuses ;  
    uint256 public total_users = 1 ;
    uint256 public coFounder_count = 0 ;
    uint256 public shareHolder_count = 0 ;
   
    uint256 public total_deposited ;
    uint256 public total_withdraw ;
    
    event Upline(address indexed addr, address indexed upline) ;
    event NewDeposit(address indexed addr, uint256 amount) ;
    event DirectPayout(address indexed addr, address indexed from, uint256 amount) ;
    event MatchPayout(address indexed addr, address indexed from, uint256 amount) ;
    event PoolPayout(address indexed addr, uint256 amount) ;
    event WhalePayout(address indexed addr, uint256 amount) ;
    event WonderPayout(address indexed addr, uint256 amount) ;
    event ActivePayout(address indexed addr, uint256 amount) ;
    event Withdraw(address indexed addr, uint256 amount) ;
    event LimitReached(address indexed addr, uint256 amount) ; 
    
    address payable public owner ; 
    address payable public admin1 ;
    address payable public admin2 ;
    address payable public admin3 ;
    address payable public admin4 ;
    address payable public alt_owner ;

    constructor(address payable _owner, 
                address payable _admin1, 
                address payable _admin2, 
                address payable _admin3, 
                address payable _admin4, 
                address payable _alt_owner) public {

        owner = _owner;
        admin1 = _admin1;
        admin2 = _admin2;
        admin3 = _admin3;
        admin4 = _admin4;
		alt_owner = _alt_owner;
 
        ref_bonuses.push(30);
        ref_bonuses.push(10);
        ref_bonuses.push(5);
        ref_bonuses.push(5);  
        ref_bonuses.push(5);
        ref_bonuses.push(5); // 60

        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10); // 90 

        pool_bonuses.push(40);
        pool_bonuses.push(20);
        pool_bonuses.push(15);
        pool_bonuses.push(15);
        pool_bonuses.push(10);

        whale_bonuses.push(50);
        whale_bonuses.push(30);
        whale_bonuses.push(20);

        users[owner].payouts = 0;
        users[owner].deposit_amount = MIN_DEPOSIT;
        users[owner].deposit_payouts = 0;
        users[owner].isActive = 1;
        users[owner].userid = 1;
        users[owner].referrals = 9;
        users[owner].deposit_time = uint40(block.timestamp) ;
        usertotals[owner].total_deposits += MIN_DEPOSIT ; 
        users[owner].total_business = 0 ;
        ids[1] = owner ;
     }
 
    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && 
		(users[_upline].deposit_time > 0 || _upline == owner)) {
            
            users[_addr].upline = _upline;
            users2[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++; 

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break; 
                usertotals[_upline].total_structure++; 
                _upline = users[_upline].upline;
            }
        }
    }

    function _deposit(address _addr, uint256 _amount) private {
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");
 
        if(users[_addr].deposit_time > 0) { 
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_amount >= users[_addr].deposit_amount  , "Bad amount");
        }
        else require(_amount >= MIN_DEPOSIT  , "Bad amount"); 

        if(_amount >= coFounder_value && coFounder_count <= 1000){
            usertotals[_addr].coFounder = true;
            coFounder_count++;
            if( usertotals[_addr].shareHolder = true){
                 shareHolder_count--; 
                 usertotals[_addr].shareHolder = false; 
            }
        } else if (_amount >= shareHolder_value && shareHolder_count <= million){
           usertotals[_addr].shareHolder = true; 
           shareHolder_count++; 
        }

        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].isActive = 1;
        users[_addr].total_business = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        if(usertotals[_addr].total_deposits == 0){
            users[_addr].userid = total_users ; 
            ids[total_users] =  _addr;
        }
        usertotals[_addr].total_deposits += _amount;
        usertotals[_addr].wonder_time = uint40(block.timestamp);

        address _upline = users[_addr].upline ;
 
        total_deposited += _amount;
        
        emit NewDeposit(_addr, _amount);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break; 
                users[_upline].total_business += _amount; 
                _upline = users[_upline].upline;
            } 
        address up = users[_addr].upline; 
 
        if( users[up].deposit_amount >= wonder_min_deposit ){
                 // wonder users

            if(block.timestamp < (usertotals[up].wonder_time + wonder_period) && users[up].deposit_amount <= _amount && _amount >= wonder_min_deposit){
                users[up].wonder_directs++;
            
            if(users[up].wonder_directs % active_directs1 == 0 ){
                users[up].wonder_bonus += users[up].deposit_amount;
                 usertotals[up].wonder_time = uint40(block.timestamp);
                emit WonderPayout(up, users[up].deposit_amount);
              }
            }
        } else {
            // active performer users
            if((block.timestamp <  users[up].deposit_time + active_period) && users[up].deposit_amount <= _amount && _amount < wonder_min_deposit){
                users2[up].active_directs++;
                users2[up].active_deposits += _amount;
            
            if(users2[up].active_directs == active_directs1 ){
                uint256 _bonus = 15*users2[up].active_deposits/100; // 15 percent
                users2[up].active_bonus += _bonus;
                users2[up].active_deposits = 0; // Reset
                emit ActivePayout(up, _bonus);

             } else if(users2[up].active_directs == active_directs2 ){
                uint256 _bonus = 10*users2[up].active_deposits/100; // 10 percent
                users2[up].active_bonus += _bonus;
                users2[up].active_deposits = 0; // Reset
                emit ActivePayout(up, _bonus);

             } else if(users2[up].active_directs == active_directs3 ){
                uint256 _bonus = 8*users2[up].active_deposits/100; // 8 percent
                users2[up].active_bonus += _bonus;
                users2[up].active_deposits = 0; // Reset
                emit ActivePayout(up, _bonus); 
             }
           }
        }
  
        if(up != address(0)) {
            users[up].direct_bonus += _amount*aff_bonus/100; 
            emit DirectPayout(up, _addr,  _amount*aff_bonus/100);
        } 

        _poolDeposits(_addr, _amount);
        _whaleDeposits(_addr, _amount);

        if(pool_last_draw + pool_period < block.timestamp) {
            _drawPool();
            _drawWhale();
        }

         admin1.transfer(_amount * admin_fee1 / 1000); 
         admin2.transfer(_amount * admin_fee1 / 1000); 
         admin3.transfer(_amount * admin_fee1 / 1000); 
         admin4.transfer(_amount * admin_fee2 / 1000);  // Reserve Fund

    }

     function _poolDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount * 7 / 100;
        if(pool_balance > 10*mainDivider){
            pool_balance = 10*mainDivider;
        }

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

     function _whaleDeposits(address _addr, uint256 _amount) private {
       
        whale_balance += _amount * 3 / 100; 
        if(whale_balance > 6*mainDivider){
            whale_balance = 6*mainDivider;
        }

        whale_users_deposits[pool_cycle][_addr] = _amount;

        for(uint8 i = 0; i < whale_bonuses.length; i++) {

            if(whale_top[i] == address(0)) {
                whale_top[i] = _addr;
                break;
            }
            
            if(whale_users_deposits[pool_cycle][_addr] > 
                whale_users_deposits[pool_cycle][whale_top[i]]) {

                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if(whale_top[j] == _addr) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            whale_top[k] = whale_top[k + 1];
                        }
                        break;
        }
    }}} 
  }

    
    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = pool_balance / 10;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = draw_amount * pool_bonuses[i] / 100;

            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;

            emit PoolPayout(pool_top[i], win);
        }
        
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    } 
  
    function _drawWhale() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 whale_draw_amount = whale_balance / 10;

        for(uint8 i = 0; i < whale_bonuses.length; i++) {
            if(whale_top[i] == address(0)) break;

            uint256 whale_win = whale_draw_amount * whale_bonuses[i] / 100;

            users2[whale_top[i]].whale_bonus += whale_win;
            whale_balance -= whale_win;

            emit WhalePayout(whale_top[i], whale_win);
        }
        
        for(uint8 i = 0; i < whale_bonuses.length; i++) {
            whale_top[i] = address(0);
        }
    } 

     function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount * ref_bonuses[i] / 100;
                
                users[up].gen_bonus += bonus;

                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }
 
    function deposit(address _upline) payable external {

         _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);

    }

 
    function withdraw() external {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        
        require(users[msg.sender].payouts < max_payout, "Full payouts");

        // Deposit payout
        if(to_payout > 0) {
            if(users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].payouts;
            } 
            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;

            _refPayout(msg.sender, to_payout);
        }
        
        // Direct payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].direct_bonus > 0) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].direct_bonus -= direct_bonus;
            users[msg.sender].payouts += direct_bonus;
            to_payout += direct_bonus;
        } 

          // Pool payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].pool_bonus > 0) {
            uint256 pool_bonus = users[msg.sender].pool_bonus;

            if(users[msg.sender].payouts + pool_bonus > max_payout) {
                pool_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].pool_bonus -= pool_bonus;
            users[msg.sender].payouts += pool_bonus;
            to_payout += pool_bonus;
        } 
 
        // Generation payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].gen_bonus > 0) {
            uint256 gen_bonus = users[msg.sender].gen_bonus;

            if(users[msg.sender].payouts + gen_bonus > max_payout) {
                gen_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].gen_bonus -= gen_bonus;
            users[msg.sender].payouts += gen_bonus;
            to_payout += gen_bonus;
        }

        // Whale payout
        if(users[msg.sender].payouts < max_payout && users2[msg.sender].whale_bonus > 0) {
            uint256 whale_bonus = users2[msg.sender].whale_bonus;

            if(users[msg.sender].payouts + whale_bonus > max_payout) {
                whale_bonus = max_payout - users[msg.sender].payouts;
            }

            users2[msg.sender].whale_bonus -= whale_bonus;
            users[msg.sender].payouts += whale_bonus;
            to_payout += whale_bonus;
        }

        if(users[msg.sender].deposit_amount >= wonder_min_deposit){
            // Wonder payout
            if(users[msg.sender].payouts < max_payout && users[msg.sender].wonder_bonus > 0) {
            uint256 wonder_bonus = users[msg.sender].wonder_bonus;

            if(users[msg.sender].payouts + wonder_bonus > max_payout) {
                wonder_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].wonder_bonus -= wonder_bonus;
            users[msg.sender].payouts += wonder_bonus;
            to_payout += wonder_bonus;
            }

        } else {
            // Active Promoter payout
            if(users[msg.sender].payouts < max_payout && users2[msg.sender].active_bonus > 0) {
            uint256 active_bonus = users2[msg.sender].active_bonus;

            if(users[msg.sender].payouts + active_bonus > max_payout) {
                active_bonus = max_payout - users[msg.sender].payouts;
            }

            users2[msg.sender].active_bonus -= active_bonus;
            users[msg.sender].payouts += active_bonus;
            to_payout += active_bonus;
            }

        }
        
        require(to_payout > 0, "Zero payout");
        
        usertotals[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;
        if(to_payout > 0){
             msg.sender.transfer(to_payout); 
        }

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
            users[msg.sender].isActive = 0;
        }
    }
    
    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);
	  
      uint256 total_rate1 = getTotalRate();
      uint256 total_rate = total_rate1*million/864;
         if(users[_addr].deposit_payouts < max_payout) {
             payout = (users[_addr].deposit_amount * total_rate  / mainDivider) * (block.timestamp - users[_addr].deposit_time) - users[_addr].deposit_payouts; 
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            } 
        } 
    }

    function getUserDividends(address _addr) view external returns(uint256) {
      uint256  max_payout = this.maxPayoutOf(users[_addr].deposit_amount);
 
      uint256 total_rate1 = getTotalRate();
      uint256 total_rate = total_rate1*million/864;
      uint256 payout;
        if(users[_addr].deposit_payouts < max_payout) {
             payout = (users[_addr].deposit_amount * total_rate  / mainDivider) * (block.timestamp - users[_addr].deposit_time) - users[_addr].deposit_payouts; 
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
        return payout;
    }    
 
	function getTotalRate() internal view returns(uint256) {
	 
 		 uint256 steps =  1*total_deposited/CONTRACT_BALANCE_STEP ;

         if(steps > 370){
             steps = 370; 
         }  
 
         uint256 total1 = BASE_PERCENT + steps;
         if(total1 > 600){
             total1 = 600;
         }
         
        return total1 ;
	}

    /*
        Only external call
    */ 

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}  

	function getRate() external view returns(uint256) { 
        uint256 steps =  1*total_deposited/CONTRACT_BALANCE_STEP ;

         if(steps > 370){
             steps = 370; 
         }  
         uint256 total1 = BASE_PERCENT + steps;
         if(total1 > 600){
             total1 = 600;
         } 
        return total1 ;
	}

    function getContractBonus() external view returns(uint256) {
      
        uint256 steps = 1*total_deposited/CONTRACT_BALANCE_STEP ;

         if(steps > 370){
             steps = 370;
         }  
         uint256 total_step = steps;  
        return total_step ;
    } 

    function maxPayoutOf(uint256 _amount) external pure returns(uint256) { 
			return  _amount * 250 / 100; 
    } 

	function getUserBalance(address _addr) external view returns (uint256) {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(_addr); 
 
        // Deposit payout
        if(to_payout > 0) {
            if(users[_addr].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[_addr].payouts;
            } 
         }
        
        // Direct payout
        if(users[_addr].payouts < max_payout && users[_addr].direct_bonus > 0) {
            uint256 direct_bonus = users[_addr].direct_bonus;
            to_payout += direct_bonus;

            if(users[_addr].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[_addr].payouts;
            } 
           
         } 
       
        // Match payout
        if(users[_addr].payouts < max_payout && users[_addr].gen_bonus > 0) {
            uint256 gen_bonus = users[_addr].gen_bonus;
           to_payout += gen_bonus;

            if(users[_addr].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[_addr].payouts;
            } 
        } 

          // Pool payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].pool_bonus > 0) {
            uint256 pool_bonus = users[msg.sender].pool_bonus;
            to_payout += pool_bonus;

            if(users[_addr].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[_addr].payouts;
            } 
        }

          // Wonder payout 
        if(users[msg.sender].payouts < max_payout && users[msg.sender].wonder_bonus > 0) {
            uint256 wonder_bonus = users[msg.sender].wonder_bonus;
            to_payout += wonder_bonus;

            if(users[_addr].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[_addr].payouts;
            } 
        }

        // Whale payout
        if(users[msg.sender].payouts < max_payout && users2[msg.sender].whale_bonus > 0) {
            uint256 whale_bonus = users2[msg.sender].whale_bonus;
            to_payout += whale_bonus;

            if(users[_addr].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[_addr].payouts;
            } 
        }

        if(users[msg.sender].deposit_amount >= wonder_min_deposit){
            // Wonder payout
            if(users[msg.sender].payouts < max_payout && users[msg.sender].wonder_bonus > 0) {
            uint256 wonder_bonus = users[msg.sender].wonder_bonus;
            to_payout += wonder_bonus;

            if(users[_addr].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[_addr].payouts;
                } 
            }

        } else {
            // Active Promoter payout
            if(users[msg.sender].payouts < max_payout && users2[msg.sender].active_bonus > 0) {
            uint256 active_bonus = users2[msg.sender].active_bonus;
            to_payout += active_bonus;

            if(users[_addr].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[_addr].payouts;
                } 
            }

        }
        return to_payout;
    }   
// usertotals[_addr].shareHolder, usertotals[_addr].coFounder

    function updateCoFounder(address _addr) public {
		require(msg.sender == owner || msg.sender == alt_owner, "Not allowed");
        if(usertotals[_addr].coFounder == true){
            usertotals[_addr].coFounder = false ;
        } else {
           usertotals[_addr].coFounder = true ; 
        } 
	} 
    function updateShareHolder(address _addr) public {
		require(msg.sender == owner || msg.sender == alt_owner, "Not allowed");
        if(usertotals[_addr].shareHolder == true){
            usertotals[_addr].shareHolder = false ;
        } else {
           usertotals[_addr].shareHolder = true ; 
        } 
	} 
    function getMemberStatus(address _addr)  external view returns (string memory){ 
        if(usertotals[_addr].coFounder == true){
            return "coFounder";
        } else if(usertotals[_addr].shareHolder == true){
            return "shareHolder";

        } else {
            return "member";
        }
    }

    function changeCoFounderValue(uint256 _newValue) public {
		require(msg.sender == owner || msg.sender == alt_owner, "Not allowed");
		coFounder_value = _newValue;
	} 

    function changeshareHolderValue(uint256 _newValue) public {
		require(msg.sender == owner || msg.sender == alt_owner, "Not allowed");
		shareHolder_value = _newValue;
	} 
 
    function changeAdmin1(address payable _newAdmin1) public {
		require(msg.sender == owner || msg.sender == alt_owner || msg.sender == admin1 , "Not allowed");
		admin1 = _newAdmin1;
	} 

	function changeAdmin2(address payable _newAdmin2) public {
		require(msg.sender == owner || msg.sender == alt_owner || msg.sender == admin2, "Not allowed");
		admin2 = _newAdmin2;
	} 

    function changeAdmin3(address payable _newAdmin3) public {
		require(msg.sender == owner || msg.sender == alt_owner || msg.sender == admin3, "Not allowed");
		admin3 = _newAdmin3;
	} 

    function changeAdmin4(address payable _newAdmin4) public {
		require(msg.sender == owner || msg.sender == alt_owner || msg.sender == admin4, "Not allowed");
		admin4 = _newAdmin4;
	}  
   
    function getAdmin() external view returns (address){ 
        return owner;
    } 
    function getID(address _addr) external view returns (uint256){ 
        return users[_addr].userid;
    }
    function getAddressFromID(uint256 _id) external view returns (address){ 
        return ids[_id];
    } 

    function getUser() external view returns (address){ 
        return alt_owner;
    } 
 
    function admin1Address() external view returns (address){ 
        return admin1;
    } 
    function admin2Address() external view returns (address){ 
        return admin2;
    } 
    function admin3Address() external view returns (address){ 
        return admin3;
    } 
    function admin4Address() external view returns (address){ 
        return admin4;
    } 
    function getNow() external view returns (uint256){ 
        return block.timestamp;
    }

    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus , uint256 gen_bonus, uint256 user_status) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].gen_bonus, users[_addr].isActive );
    }

    function userInfo2(address _addr) view external returns(uint256 wonder_bonus , uint256 wonder_directs, uint256 whale_bonus , uint256 active_directs, uint256 active_bonus, bool share_status, bool cofounder_status) {
        return (users[_addr].wonder_bonus, users[_addr].wonder_directs,  users2[_addr].whale_bonus, users2[_addr].active_directs, users2[_addr].active_bonus, usertotals[_addr].shareHolder, usertotals[_addr].coFounder);
    }

    function poolBonus(address _addr) view external returns(uint256){
        return users[_addr].pool_bonus;
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure,   uint256 deposit_payouts, uint256 total_business ) {
        return (users[_addr].referrals, usertotals[_addr].total_deposits, usertotals[_addr].total_payouts, usertotals[_addr].total_structure,  users[_addr].deposit_payouts, users[_addr].total_business);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider ) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]] );
    } 
     
    function poolTopInfo() view external returns(address[5] memory addrs, uint256[5] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    } 

    function whaleTopInfo() view external returns(address[3] memory whale_addrs, uint256[3] memory whale_deps) {
        for(uint8 i = 0; i < whale_bonuses.length; i++) {
            if(whale_top[i] == address(0)) break;

            whale_addrs[i] = whale_top[i];
            whale_deps[i] = whale_users_deposits[pool_cycle][whale_top[i]];
        }
    } 

    // function TestMyDividends(uint256 deposit_amount, uint256 time_difference) view external returns(uint256 payout, uint256 total_rate, uint256 total_rate1) {
     
    //   total_rate1 = getTotalRate();
    //   total_rate =  1+total_rate1*million/864 ; 
    //   payout = (deposit_amount * total_rate  / million) * time_difference  ;  
    //  }   
}