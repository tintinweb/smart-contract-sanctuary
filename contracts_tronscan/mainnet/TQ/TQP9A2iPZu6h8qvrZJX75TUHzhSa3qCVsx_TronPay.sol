//SourceUnit: tron_pay (1).sol

pragma solidity 0.5.10;

contract TronPay {
    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 dep_ref_payouts;
        uint256 direct_bonus;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint40 last_withdraw_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
    }

    struct Insurances {
        uint256 total_insurance;
        uint256 current_insurance;
    }

    address payable public owner;
    address payable public admin_fee;
    address payable public insurance_fund;
    address payable public default_referral;

    mapping(address => User) public users;
    mapping(address => Insurances) public insurances;

    uint8[] public ref_bonuses;

    uint8[] public pool_bonuses;
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    uint256 public last_pool_balance;
    uint256 public insurance_balance;
    uint256 public insurance_members;

    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_count_sum;
    mapping(address => uint8) public pool_new_users;
    mapping(uint256 => mapping(uint8 => address)) public pool_top;
    mapping(uint256 => mapping(uint8 => address)) public pool_top_count;

    mapping(address => mapping(uint8 => uint256)) public team_level_members;
    mapping(address => mapping(uint8 => uint256)) public team_level_amount;

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

    constructor(address payable _owner) public {
        owner = _owner;
        
        admin_fee = owner;
        insurance_fund = 0xaAa4bF9b188EB33c8e7E4db583377993d95bdb2B;
        default_referral = 0xB504AE909c16b22e525dA9F473849871cD97381B;
        
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);

        pool_bonuses.push(10); // 0.1%
        pool_bonuses.push(10);
        pool_bonuses.push(10);
        pool_bonuses.push(10);
        pool_bonuses.push(10);
    }

    function() payable external {
        _deposit(msg.sender, msg.value);
        _insurance(msg.sender, msg.value);
    }

    // Referral set up
    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == default_referral)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++;

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                users[_upline].total_structure++;

                team_level_members[_upline][i] += 1;
                team_level_amount[_upline][i] += _amount;

                _upline = users[_upline].upline;
            }
        }
    }

    function _deposit(address _addr, uint256 _amount) private {
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            
            require(users[_addr].dep_ref_payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
        }
        else require(_amount >= 100, "Bad amount");
        
        users[_addr].dep_ref_payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;
        insurances[_addr].current_insurance = 0;

        total_deposited += _amount;
        
        emit NewDeposit(_addr, _amount);

        _pollDeposits(_addr, _amount);

        if(pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
        }

        if(_addr != owner){
            admin_fee.transfer(_amount);
        }
    }

    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount * 1 / 100;

        address upline = users[_addr].upline;

        if(upline == address(0)) return;
        
        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[pool_cycle][i] == upline) break;

            if(pool_top[pool_cycle][i] == address(0)) {
                pool_top[pool_cycle][i] = upline;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[pool_cycle][i]]) {
                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top[pool_cycle][j] == upline) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[pool_cycle][k] = pool_top[pool_cycle][k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
                    pool_top[pool_cycle][j] = pool_top[pool_cycle][j - 1];
                }

                pool_top[pool_cycle][i] = upline;

                break;
            }
        }

        if(pool_new_users[_addr] < 1){
            pool_new_users[_addr] = 1;
            pool_users_refs_count_sum[pool_cycle][upline] += 1;

            for(uint8 i = 0; i < pool_bonuses.length; i++) {
                if(pool_top_count[pool_cycle][i] == upline) break;

                if(pool_top_count[pool_cycle][i] == address(0)) {
                    pool_top_count[pool_cycle][i] = upline;
                    break;
                }

                if(pool_users_refs_count_sum[pool_cycle][upline] > pool_users_refs_count_sum[pool_cycle][pool_top_count[pool_cycle][i]]) {
                    for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                        if(pool_top_count[pool_cycle][j] == upline) {
                            for(uint8 k = j; k <= pool_bonuses.length; k++) {
                                pool_top_count[pool_cycle][k] = pool_top_count[pool_cycle][k + 1];
                            }
                            break;
                        }
                    }

                    for(uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
                        pool_top_count[pool_cycle][j] = pool_top_count[pool_cycle][j - 1];
                    }

                    pool_top_count[pool_cycle][i] = upline;

                    break;
                }
            }
        }
    }

    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);

        uint256 draw_amount = pool_balance;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[pool_cycle][i] == address(0)) break;

            uint256 win = draw_amount / pool_bonuses[i];
            users[pool_top[pool_cycle][i]].pool_bonus += win;

            emit PoolPayout(pool_top[pool_cycle][i], win);
        }

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top_count[pool_cycle][i] == address(0)) break;

            uint256 win = draw_amount / pool_bonuses[i];
            users[pool_top_count[pool_cycle][i]].pool_bonus += win;

            emit PoolPayout(pool_top_count[pool_cycle][i], win);
        }

        last_pool_balance = pool_balance;
        pool_balance = 0;
        pool_cycle++;
    }

    // Initial communication to contract. deposit some amount.
    function deposit(address _upline) payable external {
        _setUpline(msg.sender, _upline, msg.value);
        _deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        (uint256 to_payout, uint256 max_dep_payout) = this.payoutOf(msg.sender);
        
        require(users[msg.sender].dep_ref_payouts < max_dep_payout, "Full payouts");
        require(users[msg.sender].last_withdraw_time <= 0 || ((block.timestamp - users[msg.sender].last_withdraw_time) / 1 days) >= 1, "Only one withdraw allowed in 24 hours.");

        // Deposit payout
        if(to_payout > 0) {
            if(users[msg.sender].dep_ref_payouts + to_payout > max_dep_payout) {
                to_payout = max_dep_payout - users[msg.sender].dep_ref_payouts;
            }

            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].dep_ref_payouts += to_payout;

            _refPayout(msg.sender, to_payout);
        }
        
        // Match payout
        if(users[msg.sender].dep_ref_payouts < max_dep_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].dep_ref_payouts + match_bonus > max_dep_payout) {
                match_bonus = max_dep_payout - users[msg.sender].dep_ref_payouts;
            }

            users[msg.sender].match_bonus -= match_bonus;
            users[msg.sender].dep_ref_payouts += match_bonus;
            to_payout += match_bonus;
        }

        // Pool payout
        if(users[msg.sender].dep_ref_payouts < max_dep_payout && users[msg.sender].pool_bonus > 0) {
            uint256 pool_bonus = users[msg.sender].pool_bonus;

            if(users[msg.sender].dep_ref_payouts + pool_bonus > max_dep_payout) {
                pool_bonus = max_dep_payout - users[msg.sender].dep_ref_payouts;
            }

            users[msg.sender].pool_bonus -= pool_bonus;
            users[msg.sender].dep_ref_payouts += pool_bonus;
            to_payout += pool_bonus;
        }

        require(to_payout > 0, "Zero payout");
        
        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;

        msg.sender.transfer(to_payout);
        users[msg.sender].last_withdraw_time = uint40(block.timestamp);

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].dep_ref_payouts >= max_dep_payout) {
            emit LimitReached(msg.sender, users[msg.sender].dep_ref_payouts);
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

    function insurance() payable external {
        _insurance(msg.sender, msg.value);
    }

    function _insurance(address _addr, uint256 _amount) private {
        (, uint256 max_dep_payout) = this.payoutOf(_addr);
        
        require((max_dep_payout - users[_addr].dep_ref_payouts) > 0, "No active investments");
        require(insurances[_addr].current_insurance <= 0, "Insurance exists.");

        insurance_balance += _amount;

        if(insurances[_addr].total_insurance <= 0){
            insurance_members += 1;
        }

        insurances[_addr].total_insurance += _amount;
        insurances[_addr].current_insurance = _amount;

        insurance_fund.transfer(_amount);
    }

    // Calculating the maximum payable amount based on user's deposit amount.
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 300 / 100;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {
            payout = ((users[_addr].deposit_amount * ((block.timestamp - users[_addr].deposit_time) / 1 days) / 100) / 2) - users[_addr].deposit_payouts;
            
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(uint40 last_withdraw_time, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus) {

        return (users[_addr].last_withdraw_time, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].dep_ref_payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure, uint256 dep_ref_payouts, uint256 _today_ref_members, uint256 _today_ref_amount) {

        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure, users[_addr].dep_ref_payouts, pool_users_refs_count_sum[pool_cycle][_addr], pool_users_refs_deposits_sum[pool_cycle][_addr]);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider, uint256 _pool_top_count) {

        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[pool_cycle][0]], pool_users_refs_count_sum[pool_cycle][pool_top_count[pool_cycle][0]]);
    }

    function poolTopInfo() view external returns(address[5] memory addrs, uint256[5] memory deps, uint256 pool_amnt) {

        if(pool_cycle > 0){
            for(uint8 i = 0; i < pool_bonuses.length; i++) {
                if(pool_top[pool_cycle - 1][i] == address(0)) break;

                addrs[i] = pool_top[pool_cycle - 1][i];
                deps[i] = pool_users_refs_deposits_sum[pool_cycle - 1][pool_top[pool_cycle - 1][i]];
            }

            pool_amnt = last_pool_balance;
        }
    }

    function poolTopCountInfo() view external returns(address[5] memory addrs, uint256[5] memory count, uint256 pool_amnt) {

        if(pool_cycle > 0){
            for(uint8 i = 0; i < pool_bonuses.length; i++) {
                if(pool_top_count[pool_cycle - 1][i] == address(0)) break;

                addrs[i] = pool_top_count[pool_cycle - 1][i];
                count[i] = pool_users_refs_count_sum[pool_cycle - 1][pool_top_count[pool_cycle - 1][i]];
            }

            pool_amnt = last_pool_balance;
        }
    }

    function teamInfo(address _addr) view external returns(uint256[21] memory level_members, uint256[21] memory level_amount, uint256 referrals) {

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            level_members[i] = team_level_members[_addr][i];
            level_amount[i] = team_level_amount[_addr][i];
        }

        referrals = users[_addr].referrals;
    }

    function insuranceInfo(address _addr) view external returns(uint256 _insurance_balance, uint256 _insurance_members, uint256 _user_total_insurance, uint256 _user_current_insurance, address _upline) {

        return (insurance_balance, insurance_members, insurances[_addr].total_insurance, insurances[_addr].current_insurance, users[_addr].upline);
    }
}