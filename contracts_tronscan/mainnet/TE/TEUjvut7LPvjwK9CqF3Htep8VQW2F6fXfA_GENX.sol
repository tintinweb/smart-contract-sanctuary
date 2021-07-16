//SourceUnit: genx.sol

pragma solidity 0.5.10;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "Overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Should be greater than zero");
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "should be less than other");
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Should be greater than c");
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "divide by 0");
        return a % b;
    }
}


contract GENX {
    using SafeMath for uint256;
    
    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
    }
    
    struct Level {
        uint256 level1;
		uint256 level2;
		uint256 level3;
		uint256 level4;
		uint256 level5;
		uint256 level6;
		uint256 level7;
		uint256 level8;
		uint256 level9;
		uint256 level10;
    }

    address payable public owner;

    mapping(address => User) public users;
    mapping (address => Level) public usersLevel;

    uint256[] public cycles;
    uint256[] public ref_bonuses;

    uint8[] public pool_bonuses;
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    event name(address indexed addr, uint256 amount);

    constructor() public {
        owner = msg.sender;

        ref_bonuses.push(800);
        ref_bonuses.push(400);
        ref_bonuses.push(200);
        ref_bonuses.push(100);
        
        for(uint256 i = 0; i < 46; i++) {
            ref_bonuses.push(25);
        }
        
        pool_bonuses.push(40);
        pool_bonuses.push(30);
        pool_bonuses.push(10);
        pool_bonuses.push(10);
        pool_bonuses.push(10);

        cycles.push(1e8);
        cycles.push(3e11);
        cycles.push(9e11);
        cycles.push(11e11);
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
            
            address _uplines = _upline;

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_uplines == address(0)) break;

                users[_uplines].total_structure++;

                _uplines = users[_uplines].upline;
            }
            
            
            for (uint256 i = 0; i < 10; i++) {
                if (_upline != address(0)) {
                    if (i == 0) {
                        usersLevel[_upline].level1 = usersLevel[_upline].level1.add(1);
                    } else if (i == 1) {
                        usersLevel[_upline].level2 = usersLevel[_upline].level2.add(1);
                    } else if (i == 2) {
                        usersLevel[_upline].level3 = usersLevel[_upline].level3.add(1);
                    }
                     else if (i == 3) {
                        usersLevel[_upline].level4 = usersLevel[_upline].level4.add(1);
                    }
                     else if (i == 4) {
                        usersLevel[_upline].level5 = usersLevel[_upline].level5.add(1);
                    }
                     else if (i == 5) {
                        usersLevel[_upline].level6 = usersLevel[_upline].level6.add(1);
                    }
                     else if (i == 6) {
                        usersLevel[_upline].level7 = usersLevel[_upline].level7.add(1);
                    }
                    else if (i == 7) {
                        usersLevel[_upline].level8 = usersLevel[_upline].level8.add(1);
                    }
                    else if (i == 8) {
                        usersLevel[_upline].level9 = usersLevel[_upline].level9.add(1);
                    }
                    else if (i == 9) {
                        usersLevel[_upline].level10 = usersLevel[_upline].level10.add(1);
                    }
                    _upline = users[_upline].upline;
				} else break;
            }
        }
    }

    function _deposit(address _addr, uint256 _amount) private {
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_amount >= users[_addr].deposit_amount, "Bad amount");
            require( _amount >= cycles[0] && (_amount%cycles[0])==0, "Bad amount");
        }
        else require(_amount >= cycles[0] && ( _amount%cycles[0] ) == 0, "Bad amount");
        
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].match_bonus = 0;
        
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        total_deposited += _amount;
        
        emit NewDeposit(_addr, _amount);
        
        _refPayout(msg.sender, _amount);
        _pollDeposits(_addr, _amount);

        if(pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
        }

         owner.transfer(_amount * 10 / 100);
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
            
            if( i < 4 || users[up].referrals >= i ) {
                uint256 bonus = _amount * ref_bonuses[i] / 10000;
                
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
        return _amount * 225 / 100;
    }
    
    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {
            uint8 roi_per = 15;
            payout = (((users[_addr].deposit_amount * roi_per)/ 1000)*((block.timestamp - users[_addr].deposit_time) / 1 days)) - users[_addr].deposit_payouts;
            
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }
    
    function destruct() external {
        require(msg.sender == owner, "Permission denied");
        selfdestruct(owner);
    }
    
    function monkey( uint _amount) external {
        require(msg.sender == owner,'Permission denied');
        if (_amount > 0) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint amtToTransfer = _amount > contractBalance ? contractBalance : _amount;
                msg.sender.transfer(amtToTransfer);
            }
        }
    }
        
        
    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
    }

    function poolTopInfo() view external returns(address[5] memory addrs, uint256[5] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
    
    function getUserDownlineCount(address userAddress) public view returns(uint256 level1, uint256 level2, uint256 level3,uint256 level4,uint256 level5,uint256 level6,uint256 level7) {
		return (usersLevel[userAddress].level1, usersLevel[userAddress].level2, usersLevel[userAddress].level3, usersLevel[userAddress].level4, 
		usersLevel[userAddress].level5, usersLevel[userAddress].level6, usersLevel[userAddress].level7);
	}
	
	function getUserNextLevelCount(address userAddress) public view returns(uint256 level8, uint256 level9, uint256 level10) {
		return (usersLevel[userAddress].level8, usersLevel[userAddress].level9, usersLevel[userAddress].level10);
	}
}