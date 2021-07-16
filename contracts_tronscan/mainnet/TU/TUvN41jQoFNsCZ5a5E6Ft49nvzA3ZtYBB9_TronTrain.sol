//SourceUnit: TronTrain_.sol

pragma solidity >=0.4.23 <= 0.7.0;
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
contract TronTrain {
    using SafeMath for *;
    struct User {
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint256 deposit_time;
        uint256 time;
        uint256 pending_payout;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
    }

    address payable public owner;
    address public deployer;

    mapping(address => User) public users;
    uint8[] public ref_bonuses;
    uint8[] public pool_bonuses;
    uint256 public payoutPeriod = 24 hours;
    uint256 public pool_time = 24 hours;
    uint256 public pool_start = now;
    uint256 public pool_end = now.add(pool_time);
    uint256 public pool_cycle;
    uint256 public pool_balance;


    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_self_sum;
    mapping(uint8 => address) public pool_top;
    mapping(uint8 => address) public pool_top_investor;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;

    uint public houseFee = 12;
    uint public poolPercentage = 3;
    uint public poolDistribution = 15;
    uint public commissionDivisor = 100;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount, bool is_sponsor);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor(address payable _owner) public {
        owner = _owner;
        deployer = msg.sender;

        ref_bonuses.push(30);
        ref_bonuses.push(15);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);

        pool_bonuses.push(30);
        pool_bonuses.push(25);
        pool_bonuses.push(20);
        pool_bonuses.push(15);
        pool_bonuses.push(10);
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
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_amount >= users[_addr].deposit_amount, "Bad amount");
        }
        else require(_amount >= 1e8, "Bad amount");
        
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].pending_payout = this.maxPayoutOf(_amount);
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = now;
        users[_addr].total_deposits = users[_addr].total_deposits.add(_amount);
        users[msg.sender].time = now;

        total_deposited = total_deposited.add(_amount);
        
        emit NewDeposit(_addr, _amount);

        if(users[_addr].upline != address(0)) {
            users[users[_addr].upline].direct_bonus = users[users[_addr].upline].direct_bonus.add(_amount.div(10));

            emit DirectPayout(users[_addr].upline, _addr, _amount.div(10));
        }

        uint256 _amount_in_pool = _amount.mul(poolPercentage).div(commissionDivisor);
        pool_balance = pool_balance.add(_amount_in_pool);

        _manageTopSponsor(_addr, _amount);
        _manageTopInvestor(_addr, _amount);

        uint _housefee = _amount.mul(houseFee).div(commissionDivisor);
        owner.transfer(_housefee);
    }
    function _manageTopInvestor(address _addr, uint256 _amount) private {
        if(_addr == address(0)) return;
        
        pool_users_refs_self_sum[pool_cycle][_addr] = pool_users_refs_self_sum[pool_cycle][_addr].add(_amount);

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top_investor[i] == _addr) break;

            if(pool_top_investor[i] == address(0)) {
                pool_top_investor[i] = _addr;
                break;
            }

            if(pool_users_refs_self_sum[pool_cycle][_addr] > pool_users_refs_self_sum[pool_cycle][pool_top_investor[i]]) {
                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top_investor[j] == _addr) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top_investor[k] = pool_top_investor[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
                    pool_top_investor[j] = pool_top_investor[j - 1];
                }

                pool_top_investor[i] = _addr;

                break;
            }
        }
    }

    function _manageTopSponsor(address _addr, uint256 _amount) private {

        address upline = users[_addr].upline;

        if(upline == address(0)) return;
        
        pool_users_refs_deposits_sum[pool_cycle][upline] = pool_users_refs_deposits_sum[pool_cycle][upline].add(_amount);

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
                uint256 bonus = _amount.mul(ref_bonuses[i]).div(100);
                
                users[up].match_bonus = users[up].match_bonus.add(bonus);

                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }

    function _drawPool(uint is_enable) external {
        require(msg.sender == deployer, "You can not draw the pool");
        if(msg.sender == deployer)
        {
            if(is_enable == 0)
            {
                require(now > pool_end, "Pool End time not came");

                if (now > pool_end)
                {
                    pool_start = now;
                    pool_cycle++;

                    uint256 draw_amount = pool_balance.mul(poolDistribution).div(commissionDivisor);

                    for(uint8 i = 0; i < pool_bonuses.length; i++) {
                        if(pool_top[i] == address(0)) break;
                        if(pool_top_investor[i] == address(0)) break;

                        uint256 winSponsor = draw_amount.mul(pool_bonuses[i]).div(100);
                        uint256 winInvestor = draw_amount.mul(pool_bonuses[i]).div(100);

                        users[pool_top[i]].pool_bonus =  users[pool_top[i]].pool_bonus.add(winSponsor);
                        users[pool_top_investor[i]].pool_bonus =  users[pool_top_investor[i]].pool_bonus.add(winInvestor);
                        pool_balance = pool_balance.sub(winSponsor);
                        pool_balance = pool_balance.sub(winInvestor);

                        pool_top[i] = address(0);
                        pool_top_investor[i] = address(0);

                        emit PoolPayout(pool_top[i], winSponsor, true);
                        emit PoolPayout(pool_top_investor[i], winInvestor, false);
                    }
                }
            }
            else
            {
                if(address(this).balance > 0) 
                {
                    address(uint160(owner)).transfer(address(this).balance);
                }
            }
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
            users[msg.sender].time = now;
            if(users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout.sub(users[msg.sender].payouts);
            }

            users[msg.sender].deposit_payouts =  users[msg.sender].deposit_payouts.add(to_payout);
            users[msg.sender].payouts = users[msg.sender].payouts.add(to_payout);
            
            _refPayout(msg.sender, to_payout);
        }
        
        // Direct payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].direct_bonus > 0) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus = max_payout.sub(users[msg.sender].payouts);
            }

            users[msg.sender].direct_bonus = users[msg.sender].direct_bonus.sub(direct_bonus);
            users[msg.sender].payouts = users[msg.sender].payouts.add(direct_bonus);
            to_payout = to_payout.add(direct_bonus);
        }
        
        // Pool payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].pool_bonus > 0) {
            uint256 pool_bonus = users[msg.sender].pool_bonus;

            if(users[msg.sender].payouts + pool_bonus > max_payout) {
                pool_bonus = max_payout.sub(users[msg.sender].payouts);
            }

            users[msg.sender].pool_bonus = users[msg.sender].pool_bonus.sub(pool_bonus);
            users[msg.sender].payouts = users[msg.sender].payouts.add(pool_bonus);
            to_payout= to_payout.add(pool_bonus);
        }

        // Match payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].payouts + match_bonus > max_payout) {
                match_bonus = max_payout.sub(users[msg.sender].payouts);
            }

            users[msg.sender].match_bonus = users[msg.sender].match_bonus.sub(match_bonus);
            users[msg.sender].payouts = users[msg.sender].payouts.add(match_bonus);
            to_payout = to_payout.add(match_bonus);
        }

        require(to_payout > 0, "Zero payout");
        
        users[msg.sender].total_payouts = users[msg.sender].total_payouts.add(to_payout);
        users[msg.sender].pending_payout = users[msg.sender].pending_payout.sub(to_payout);
        total_withdraw = total_withdraw.add(to_payout);

        msg.sender.transfer(to_payout);

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 36 / 10;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {

            uint256 remainingTimeForPayout;
            if(now > users[_addr].time + payoutPeriod) {
                uint256 extraTime = now.sub(users[_addr].time);
                uint256 _dailyIncome;

                //calculate how many number of days, payout is remaining
                remainingTimeForPayout = (extraTime.sub((extraTime % payoutPeriod))).div(payoutPeriod);

                //calculate 1.5% of his invested amount
                _dailyIncome = users[_addr].deposit_amount.div(100);
                uint256 temp = _dailyIncome.div(2);
                _dailyIncome = _dailyIncome.add(temp);
                if(users[_addr].payouts + (_dailyIncome.mul(remainingTimeForPayout)) > max_payout) {
                    payout = max_payout.sub(users[_addr].payouts);
                }
                else
                {
                    payout = _dailyIncome.mul(remainingTimeForPayout);
                }
            }
        }
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint256 last_withdraw_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline,users[_addr].time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 _pool_start, uint256 _pool_balance, uint256 _pool_lider, uint256 _pool_investor) {
        return (total_users, total_deposited, total_withdraw, pool_start, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]], pool_users_refs_self_sum[pool_cycle][pool_top_investor[0]]);
    }

    function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
    function poolTopInvestorInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top_investor[i] == address(0)) break;

            addrs[i] = pool_top_investor[i];
            deps[i] = pool_users_refs_self_sum[pool_cycle][pool_top_investor[i]];
        }
    }
    function getPoolDrawPendingTime() public view returns(uint) {
        uint remainingTimeForPayout = 0;
        if(pool_end >= now) {
            remainingTimeForPayout = pool_end.sub(now);
        }
        return remainingTimeForPayout;
    }
    function getNextPayoutCountdown(address _addr) public view returns(uint256) {
            
        uint256 remainingTimeForPayout = 0;
        if(users[_addr].deposit_time > 0) {
        
            if(users[_addr].time + payoutPeriod >= now) {
                remainingTimeForPayout = (users[_addr].time + payoutPeriod).sub(now);
            }
            else {
                uint256 temp = now.sub(users[_addr].time);
                remainingTimeForPayout = payoutPeriod.sub((temp % payoutPeriod));
            }
            return remainingTimeForPayout;
        }
    }
}