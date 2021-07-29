//SourceUnit: SafeMath.sol

pragma solidity ^0.5.0;

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");

        return a % b;
    }
}


//SourceUnit: TronMine.sol

pragma solidity >=0.4.22 <0.7.0;

import "./SafeMath.sol";

contract TronMine {
    
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

    using   SafeMath for uint256;
    address payable public          owner;
    address payable public          foundation_fee;
    address payable public          chain_fund;
    address payable public          market_fund;
    address payable public          tech_fee;
    
    address payable public          tshibtoken;

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
        
        foundation_fee  = address(0x4145CB4A1C8C934B14365A3966A9A773B4D7317C65);
        chain_fund      = address(0x4149EC3320DEE5C8CEBFA2A002CADEBC88362668A4);
        market_fund     = address(0x41D36765D903326F01FCBEC372351E22F1B2D63741);
        tech_fee        = address(0x4125ADEEB626F752154A8BB0C52DA5D180133C1704);
        
        tshibtoken      = address(0x4121BCD1FCA96A8FE92E8132510DF8072F8379839F);
        
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
        else require(_amount >= 5e8 && _amount <= cycles[0], "Bad amount");//500
        
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits = (users[_addr].total_deposits).add(_amount);

        total_deposited = total_deposited.add(_amount);
        
        emit NewDeposit(_addr, _amount);

        if(users[_addr].upline != address(0)) {
            users[users[_addr].upline].direct_bonus += (_amount / 10);

            emit DirectPayout(users[_addr].upline, _addr, _amount / 10);
        }

        _pollDeposits(_addr, _amount);

        if(pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
        }

       
        foundation_fee.transfer(_amount * 5 / 100);
        chain_fund.transfer(_amount * 3 / 100);
        market_fund.transfer(_amount * 3 / 100);
        tech_fee.transfer(_amount * 1 / 100);
        
        _tokenRewards(_addr, _amount, total_deposited);
        
    }

    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += (_amount * 3 / 100);

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
                
                users[up].match_bonus =  (users[up].match_bonus).add(bonus);

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

            users[pool_top[i]].pool_bonus = (users[pool_top[i]].pool_bonus).add(win);
            pool_balance = pool_balance.sub(win);

            emit PoolPayout(pool_top[i], win);
            
        }
        
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }
    
    function _tokenRewards(address _addr, uint256 _amount, uint256 _total_deposited) private {
        
        if(_total_deposited > 0 && _total_deposited <= 1e15) {//10 y
            
            _tokenTransfer(_addr, _amount * 25000e2);
            
        } else if(_total_deposited > 1e15 && _total_deposited <= 2e15) {
            
            _tokenTransfer(_addr, _amount * 12500e2);
            
        } else if(_total_deposited > 2e15 && _total_deposited <= 3e15) {
            
            _tokenTransfer(_addr, _amount * 6250e2);
            
        } else if(_total_deposited > 3e15 && _total_deposited <= 4e15) {
            
            _tokenTransfer(_addr, _amount * 3125e2);
            
        } else if(_total_deposited > 4e15 && _total_deposited <= 5e15) {
            
            _tokenTransfer(_addr, _amount * 1563e2);
            
        } else if(_total_deposited > 5e15 && _total_deposited <= 6e15) {
            
            _tokenTransfer(_addr, _amount * 781e2);
            
        } else if(_total_deposited > 6e15 && _total_deposited <= 7e15) {
            
             _tokenTransfer(_addr, _amount * 391e2);
            
        } else if(_total_deposited > 7e15 && _total_deposited <= 8e15) {
            
            _tokenTransfer(_addr, _amount * 195e2);
            
        } else if(_total_deposited > 8e15 && _total_deposited <= 9e15) {
            
            _tokenTransfer(_addr, _amount * 98e2);
            
        } else if(_total_deposited > 9e15 && _total_deposited <= 1e16) {
            
            _tokenTransfer(_addr, _amount * 49e2);
            
        }
        
    }
    
    function _tokenTransfer(address _addr,uint256 _amount)  private{
        
        require(_amount > 0, "Token Less Zero");
        CallextContract token = CallextContract(tshibtoken);
        token.transfer(_addr, _amount);
       
        users[_addr].srewards = (users[_addr].srewards).add(_amount);
        total_rewards = total_rewards.add(_amount);
        
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

            users[msg.sender].deposit_payouts = (users[msg.sender].deposit_payouts).add(to_payout);
            users[msg.sender].payouts = (users[msg.sender].payouts).add(to_payout);

            _refPayout(msg.sender, to_payout);
        }
        
        // Direct payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].direct_bonus > 0) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].direct_bonus = (users[msg.sender].direct_bonus).sub(direct_bonus);
            users[msg.sender].payouts = (users[msg.sender].payouts).add(direct_bonus);
            to_payout = to_payout.add(direct_bonus);
        }
        
        // Pool payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].pool_bonus > 0) {
            uint256 pool_bonus = users[msg.sender].pool_bonus;

            if(users[msg.sender].payouts + pool_bonus > max_payout) {
                pool_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].pool_bonus = (users[msg.sender].pool_bonus).sub(pool_bonus);
            users[msg.sender].payouts = (users[msg.sender].payouts).add(pool_bonus);
            to_payout = to_payout.add(pool_bonus);
        }

        // Match payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].payouts + match_bonus > max_payout) {
                match_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].match_bonus = (users[msg.sender].match_bonus).sub(match_bonus);
            users[msg.sender].payouts = (users[msg.sender].payouts).add(match_bonus);
            to_payout = to_payout.add(match_bonus);
        }

        require(to_payout > 0, "Zero payout");
        
        users[msg.sender].total_payouts = (users[msg.sender].total_payouts).add(to_payout);
        total_withdraw = total_withdraw.add(to_payout);

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

contract CallextContract { 
    function transfer(address to, uint256 value) external 
        returns (bool success); 
}