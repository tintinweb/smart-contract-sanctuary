/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface Token {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);

}

contract ReefChain {
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
        uint256 payout_days;
    }

    address payable public owner;
    address payable public insuranceAddress;
    address public tokenAddr;
   
    mapping(address => User) public users;

    uint8[] public ref_bonuses;                     

    uint8[] public pool_bonuses;
    uint8[] public first_topup_pool;
    uint8[] public second_topup_pool;
    uint8[] public third_topup_pool;
    uint8[] public fourth_topup_pool;
    uint8[] public direct_ref_bonuses;

    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;

    uint40 public topup_pool_last_draw = uint40(block.timestamp);
    uint256 public topup_pool_cycle;
    uint256 public topup_pool_balance;
    uint256 public referral_pool_balance;

    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint256 => mapping(address => uint256)) public first_topup_pool_deposits_sum;
    mapping(uint256 => mapping(address => uint256)) public second_topup_pool_deposits_sum;
    mapping(uint256 => mapping(address => uint256)) public third_topup_pool_deposits_sum;
    mapping(uint256 => mapping(address => uint256)) public fourth_topup_pool_deposits_sum;

    mapping(uint8 => address) public pool_top;
    mapping(uint8 => address) public first_topup_pool_top;
    mapping(uint8 => address) public second_topup_pool_top;
    mapping(uint8 => address) public third_topup_pool_top;
    mapping(uint8 => address) public fourth_topup_pool_top;


    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event LevelPayout(address indexed addr, address indexed from, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event TopupPoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    event AppovedAmount(address indexed addr,address approvedAdd, uint256 amount);



    constructor(address payable _owner, address payable _insuranceAddress, address _tokenAddr)  {
        owner = _owner;
        insuranceAddress = _insuranceAddress;
        tokenAddr = _tokenAddr;

        direct_ref_bonuses.push(100);
        direct_ref_bonuses.push(9);
        direct_ref_bonuses.push(8);
        direct_ref_bonuses.push(7);
        direct_ref_bonuses.push(6);
        direct_ref_bonuses.push(5);
        direct_ref_bonuses.push(4);
        direct_ref_bonuses.push(3);
        direct_ref_bonuses.push(2);
        direct_ref_bonuses.push(1);
        direct_ref_bonuses.push(1);
        direct_ref_bonuses.push(2);
        direct_ref_bonuses.push(3);
        direct_ref_bonuses.push(4);
        direct_ref_bonuses.push(5);
        direct_ref_bonuses.push(6);
        direct_ref_bonuses.push(7);
        direct_ref_bonuses.push(8);
        direct_ref_bonuses.push(9);
        direct_ref_bonuses.push(10);

        ref_bonuses.push(40);
        ref_bonuses.push(30);
        ref_bonuses.push(20);
        ref_bonuses.push(10);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(4);
        ref_bonuses.push(3);
        ref_bonuses.push(2);
        ref_bonuses.push(1);
        ref_bonuses.push(5);
        ref_bonuses.push(4);
        ref_bonuses.push(3);
        ref_bonuses.push(2);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(2);
        ref_bonuses.push(3);
        ref_bonuses.push(4);
        ref_bonuses.push(5);

        pool_bonuses.push(40);
        pool_bonuses.push(30);
        pool_bonuses.push(15);
        pool_bonuses.push(10);
        pool_bonuses.push(5);

        // Topup Pool Distribution 0.88% 
        first_topup_pool.push(10);
        second_topup_pool.push(20);
        third_topup_pool.push(30);
        fourth_topup_pool.push(40);
        


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
        require(_amount <= Token(tokenAddr).balanceOf(_addr),"Token Balance of user is less");
        require(Token(tokenAddr).transferFrom(_addr,address(this), _amount),"Transfers Token From User Address to Contract");

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_amount==1700 * 1e18, "Bad amount");
        }
        else require(_amount==1700 * 1e18, "Bad amount");
        
        _amount =  1500 * 1e18;
        uint256 amountRemaining = 1700 * 1e18;

        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;
        users[_addr].payout_days = 0;


        total_deposited += amountRemaining;
        
        emit NewDeposit(_addr, _amount);
        uint256 max_payout = this.maxPayoutOf(users[users[_addr].upline].deposit_amount);

        _pollDeposits(_addr, amountRemaining); // Top Sponsor Pool - 3%
        _topupPollDeposits(_addr, amountRemaining); // Topup Pool - 0.88%
        referral_pool_balance += amountRemaining * 88 / 10000; // 0.88% for topup Pool
        address up = users[_addr].upline;
        if(users[up].payouts < max_payout) {
                uint256 payout = (users[up].deposit_amount * ((block.timestamp - users[up].deposit_time) / 1 days) / 100) - users[up].deposit_payouts;
                
                if(users[up].payouts + users[up].deposit_payouts + users[up].direct_bonus  + users[up].pool_bonus  + users[up].match_bonus + payout > max_payout) {
                    // User will get no level bonus if they go above limit
                }else{
                    if(users[_addr].upline != address(0)) {
                        if(users[users[_addr].upline].referrals % 5 == 0){ // Every 5th Direct Deposit
                            users[users[_addr].upline].direct_bonus += 75 * 1e18; // 0.88% Pool (75 TRX) Additional Reward
                            if(referral_pool_balance > 75 * 1e18){
                                referral_pool_balance -= 75 * 1e18;
                            }else{
                                referral_pool_balance =0;
                            }
                            emit DirectPayout(users[_addr].upline, _addr, ((_amount * 5) / 100));
                        }
                        levelPayout(_addr, _amount);
                    }
                }
        }
        
        if(pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
        }
        if(topup_pool_last_draw + 7 days < block.timestamp) {
            _drawTopupPool();
        }
        Token(tokenAddr).transfer(owner, amountRemaining * 5 / 100); // 5% Platform Fee
        Token(tokenAddr).transfer(insuranceAddress, amountRemaining * 2 / 100); // 2% Insurance Fund

    }

    function deposit(address _upline,uint256  _amount) external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, _amount);
    }

    function _pollDeposits(address _addr, uint256 _amount) private {

        pool_balance += _amount * 3 / 100; // 3% Top 5 Sponsor Pool

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

    function _topupPollDeposits(address _addr, uint256 _amount) private {

        topup_pool_balance += _amount * 88 / 10000; // 0.88% for topup Pool

        address upline = users[_addr].upline;

        if(upline == address(0)) return;
        

        if(users[_addr].cycle>=1 && users[_addr].cycle<=5){
        
            first_topup_pool_deposits_sum[topup_pool_cycle][_addr] = users[_addr].cycle;

            for(uint8 i = 0; i < first_topup_pool.length; i++) {
                if(first_topup_pool_top[i] == _addr) break;

                if(first_topup_pool_top[i] == address(0)) {
                    first_topup_pool_top[i] = _addr;
                    break;
                }

                if(first_topup_pool_deposits_sum[topup_pool_cycle][_addr] > first_topup_pool_deposits_sum[topup_pool_cycle][first_topup_pool_top[i]]) {
                    first_topup_pool_top[i] = _addr;
                }
            }
        }else if(users[_addr].cycle>5 && users[_addr].cycle<=13){
        
            second_topup_pool_deposits_sum[topup_pool_cycle][_addr] = users[_addr].cycle;

            for(uint8 i = 0; i < second_topup_pool.length; i++) {
                if(second_topup_pool_top[i] == _addr) break;

                if(second_topup_pool_top[i] == address(0)) {
                    second_topup_pool_top[i] = _addr;
                    break;
                }

                if(second_topup_pool_deposits_sum[topup_pool_cycle][_addr] > second_topup_pool_deposits_sum[topup_pool_cycle][second_topup_pool_top[i]]) {
                    second_topup_pool_top[i] = _addr;
                }
            }
        
        }else if(users[_addr].cycle>13 && users[_addr].cycle<=17){
        
            third_topup_pool_deposits_sum[topup_pool_cycle][_addr] = users[_addr].cycle;

            for(uint8 i = 0; i < third_topup_pool.length; i++) {
                if(third_topup_pool_top[i] == _addr) break;

                if(third_topup_pool_top[i] == address(0)) {
                    third_topup_pool_top[i] = _addr;
                    break;
                }

                if(third_topup_pool_deposits_sum[topup_pool_cycle][_addr] > third_topup_pool_deposits_sum[topup_pool_cycle][third_topup_pool_top[i]]) {
                    third_topup_pool_top[i] = _addr;
                }
            }
        }else if(users[_addr].cycle>17){        
            fourth_topup_pool_deposits_sum[topup_pool_cycle][_addr] = users[_addr].cycle;

            for(uint8 i = 0; i < fourth_topup_pool.length; i++) {
                if(fourth_topup_pool_top[i] == _addr) break;

                if(fourth_topup_pool_top[i] == address(0)) {
                    fourth_topup_pool_top[i] = _addr;
                    break;
                }

                if(fourth_topup_pool_deposits_sum[topup_pool_cycle][_addr] > fourth_topup_pool_deposits_sum[topup_pool_cycle][fourth_topup_pool_top[i]]) {
                    fourth_topup_pool_top[i] = _addr;
                }
            }
            
        }

        
    }


    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;
        uint256 daysPassed = 1;

        if(((block.timestamp - users[_addr].deposit_time) / 1 days) <= 300){
            daysPassed = ((block.timestamp - users[_addr].deposit_time) / 1 days) - users[_addr].payout_days;
        }else{
            daysPassed = 300 - users[_addr].payout_days;
        }

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 max_payout = this.maxPayoutOf(users[up].deposit_amount);

            if(users[up].payouts < max_payout) {
                uint256 payout = (users[up].deposit_amount * ((block.timestamp - users[up].deposit_time) / 1 days) / 100) - users[up].deposit_payouts;
                
                if(users[up].payouts + users[up].deposit_payouts + users[up].direct_bonus  + users[up].pool_bonus  + users[up].match_bonus + payout > max_payout) {
                    // User will get no matching bonus if they go above limit
                }else{
                    if(users[up].referrals >= i + 1) {
                        if((users[up].cycle) >= i + 1){
                            uint256 bonus = ((_amount * ref_bonuses[i] / 10000)/2) * daysPassed;
                            users[up].match_bonus += bonus;
                            emit MatchPayout(up, _addr, bonus);
                        }else{
                            uint256 bonus = (_amount * ref_bonuses[i] / 10000) * daysPassed;
                            users[up].match_bonus += bonus;
                            emit MatchPayout(up, _addr, bonus);
                        }
                    }
                }
            }
            

            up = users[up].upline;
        }
        users[_addr].payout_days += daysPassed;
    }


    function levelPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < direct_ref_bonuses.length; i++) {
            if(up == address(0)) break;
            uint256 max_payout = this.maxPayoutOf(users[up].deposit_amount);

            if(users[up].payouts < max_payout) {
                uint256 payout = (users[up].deposit_amount * ((block.timestamp - users[up].deposit_time) / 1 days) / 100) - users[up].deposit_payouts;
                
                if(users[up].payouts + users[up].deposit_payouts + users[up].direct_bonus  + users[up].pool_bonus  + users[up].match_bonus + payout > max_payout) {
                    // User will get no level bonus if they go above limit
                }else{
                    if(users[up].referrals >= i + 1) {
                        if((users[up].cycle) >= i + 1  ){
                            uint256 bonus = (_amount * direct_ref_bonuses[i] / 1000)/2;
                            users[up].direct_bonus += bonus;
                            emit LevelPayout(up, _addr, bonus);
                        }else{
                            uint256 bonus = _amount * direct_ref_bonuses[i] / 1000;
                            users[up].direct_bonus += bonus;
                            emit LevelPayout(up, _addr, bonus);
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
            uint256 max_payout = this.maxPayoutOf(users[pool_top[i]].deposit_amount);
            uint256 payout = (users[pool_top[i]].deposit_amount * ((block.timestamp - users[pool_top[i]].deposit_time) / 1 days) / 100) - users[pool_top[i]].deposit_payouts;

            if(users[pool_top[i]].payouts + users[pool_top[i]].deposit_payouts + users[pool_top[i]].direct_bonus  + users[pool_top[i]].pool_bonus  + users[pool_top[i]].match_bonus + payout > max_payout) {
                    // User will get no level bonus if they go above limit
            }else{
                uint256 win = draw_amount * pool_bonuses[i] / 100;
                users[pool_top[i]].pool_bonus += win;
                pool_balance -= win;
                emit PoolPayout(pool_top[i], win);
            }
        }
        
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }

    function _drawTopupPool() private {
        topup_pool_last_draw = uint40(block.timestamp);
        topup_pool_cycle++;

        uint256 draw_amount = topup_pool_balance;

        // 1st Pool
        for(uint8 i = 0; i < first_topup_pool.length; i++) {
            uint256 max_payout1 = this.maxPayoutOf(users[first_topup_pool_top[i]].deposit_amount);
            uint256 payout1 = (users[first_topup_pool_top[i]].deposit_amount * ((block.timestamp - users[first_topup_pool_top[i]].deposit_time) / 1 days) / 100) - users[first_topup_pool_top[i]].deposit_payouts;

            if(users[first_topup_pool_top[i]].payouts + users[first_topup_pool_top[i]].deposit_payouts + users[first_topup_pool_top[i]].direct_bonus  + users[first_topup_pool_top[i]].pool_bonus  + users[first_topup_pool_top[i]].match_bonus + payout1 > max_payout1) {
                    // User will get no level bonus if they go above limit
            }else{
                if(first_topup_pool_top[i] != address(0)){
                    uint256 win = draw_amount * first_topup_pool[i] / 100;
                    users[first_topup_pool_top[i]].pool_bonus += win;
                    topup_pool_balance -= win;
                    emit TopupPoolPayout(first_topup_pool_top[i], win);
                }
            }
        }
        
        for(uint8 i = 0; i < first_topup_pool.length; i++) {
            first_topup_pool_top[i] = address(0);
        }
    

        // 2nd Pool
        for(uint8 i = 0; i < second_topup_pool.length; i++) {
            uint256 max_payout2 = this.maxPayoutOf(users[second_topup_pool_top[i]].deposit_amount);
            uint256 payout2 = (users[second_topup_pool_top[i]].deposit_amount * ((block.timestamp - users[second_topup_pool_top[i]].deposit_time) / 1 days) / 100) - users[second_topup_pool_top[i]].deposit_payouts;

            if(users[second_topup_pool_top[i]].payouts + users[second_topup_pool_top[i]].deposit_payouts + users[second_topup_pool_top[i]].direct_bonus  + users[second_topup_pool_top[i]].pool_bonus  + users[second_topup_pool_top[i]].match_bonus + payout2 > max_payout2) {
                    // User will get no level bonus if they go above limit
            }else{
                if(second_topup_pool_top[i] != address(0)){
                    uint256 win = draw_amount * second_topup_pool[i] / 100;

                    users[second_topup_pool_top[i]].pool_bonus += win;
                    topup_pool_balance -= win;

                    emit TopupPoolPayout(second_topup_pool_top[i], win);
                }
            }
        }
        
        for(uint8 i = 0; i < second_topup_pool.length; i++) {
            second_topup_pool_top[i] = address(0);
        }
        

        // 3rd Pool
        for(uint8 i = 0; i < third_topup_pool.length; i++) {
            uint256 max_payout3 = this.maxPayoutOf(users[third_topup_pool_top[i]].deposit_amount);
            uint256 payout3 = (users[third_topup_pool_top[i]].deposit_amount * ((block.timestamp - users[third_topup_pool_top[i]].deposit_time) / 1 days) / 100) - users[third_topup_pool_top[i]].deposit_payouts;

            if(users[third_topup_pool_top[i]].payouts + users[third_topup_pool_top[i]].deposit_payouts + users[third_topup_pool_top[i]].direct_bonus  + users[third_topup_pool_top[i]].pool_bonus  + users[third_topup_pool_top[i]].match_bonus + payout3 > max_payout3) {
                    // User will get no level bonus if they go above limit
            }else{
                if(third_topup_pool_top[i] != address(0)){
                    uint256 win = draw_amount * third_topup_pool[i] / 100;

                    users[third_topup_pool_top[i]].pool_bonus += win;
                    topup_pool_balance -= win;

                    emit TopupPoolPayout(third_topup_pool_top[i], win);
                }
            }
        }
        
        for(uint8 i = 0; i < third_topup_pool.length; i++) {
            third_topup_pool_top[i] = address(0);
        }

         
        // 4th Pool
        for(uint8 i = 0; i < fourth_topup_pool.length; i++) {
            uint256 max_payout4 = this.maxPayoutOf(users[fourth_topup_pool_top[i]].deposit_amount);
            uint256 payout4 = (users[fourth_topup_pool_top[i]].deposit_amount * ((block.timestamp - users[fourth_topup_pool_top[i]].deposit_time) / 1 days) / 100) - users[fourth_topup_pool_top[i]].deposit_payouts;

            if(users[fourth_topup_pool_top[i]].payouts + users[fourth_topup_pool_top[i]].deposit_payouts + users[fourth_topup_pool_top[i]].direct_bonus  + users[fourth_topup_pool_top[i]].pool_bonus  + users[fourth_topup_pool_top[i]].match_bonus + payout4 > max_payout4) {
                    // User will get no level bonus if they go above limit
            }else{
                if(fourth_topup_pool_top[i] != address(0)){
                    uint256 win = draw_amount * fourth_topup_pool[i] / 100;

                    users[fourth_topup_pool_top[i]].pool_bonus += win;
                    topup_pool_balance -= win;

                    emit TopupPoolPayout(fourth_topup_pool_top[i], win);
                }
            }
        }
        
        for(uint8 i = 0; i < fourth_topup_pool.length; i++) {
            fourth_topup_pool_top[i] = address(0);
        }
        
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
            uint256 amountPay = 1500 * 1e18;
            _refPayout(msg.sender, amountPay);
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
        
        // Withdrawal Fee 5%
        uint256 withdrawalFee = (to_payout * 5)/100; 
        require((to_payout > withdrawalFee),"Withdrawal Fee is greater than Payout");
        
        Token(tokenAddr).transfer(msg.sender, to_payout - withdrawalFee); // Sends Withdrawal amount to user
        Token(tokenAddr).transfer(owner, withdrawalFee); // Sends Withdrawal fee to owner

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 30 / 10;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].payouts < max_payout) {
            
            payout = (users[_addr].deposit_amount * ((block.timestamp - users[_addr].deposit_time) / 1 days) / 100) - users[_addr].deposit_payouts; // Per Day (1 days)
            
            if(users[_addr].deposit_payouts + users[_addr].direct_bonus  + users[_addr].pool_bonus  + users[_addr].match_bonus + payout > max_payout) {
                payout = max_payout - (users[_addr].deposit_payouts + users[_addr].direct_bonus  + users[_addr].pool_bonus  + users[_addr].match_bonus);
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

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance,uint40 _topup_pool_last_draw, uint256 _topup_pool_balance, uint256 _pool_lider) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance,topup_pool_last_draw, topup_pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
    }

    function poolTopInfo() view external returns(address[5] memory addrs, uint256[5] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }

    function firstTopupPoolTopInfo() view external returns(address[1] memory addrs, uint256[1] memory deps) {
        for(uint8 i = 0; i < first_topup_pool.length; i++) {
            if(first_topup_pool_top[i] == address(0)) break;
            
            addrs[i] = first_topup_pool_top[i];
            deps[i] = first_topup_pool_deposits_sum[topup_pool_cycle][first_topup_pool_top[i]];
        }
    }

    function secondTopupPoolTopInfo() view external returns(address[1] memory addrs, uint256[1] memory deps) {
        for(uint8 i = 0; i < second_topup_pool.length; i++) {
            if(second_topup_pool_top[i] == address(0)) break;
            
            addrs[i] = second_topup_pool_top[i];
            deps[i] = second_topup_pool_deposits_sum[topup_pool_cycle][second_topup_pool_top[i]];
        }
    }

    function thirdTopupPoolTopInfo() view external returns(address[1] memory addrs, uint256[1] memory deps) {
        for(uint8 i = 0; i < third_topup_pool.length; i++) {
            if(third_topup_pool_top[i] == address(0)) break;
            
            addrs[i] = third_topup_pool_top[i];
            deps[i] = third_topup_pool_deposits_sum[topup_pool_cycle][third_topup_pool_top[i]];
        }
    }

    function fourthTopupPoolTopInfo() view external returns(address[1] memory addrs, uint256[1] memory deps) {
        for(uint8 i = 0; i < fourth_topup_pool.length; i++) {
            if(fourth_topup_pool_top[i] == address(0)) break;
            
            addrs[i] = fourth_topup_pool_top[i];
            deps[i] = fourth_topup_pool_deposits_sum[topup_pool_cycle][fourth_topup_pool_top[i]];
        }
    }
 
    function balanceToken() public view returns(uint256) {
        return Token(tokenAddr).balanceOf(address(this));
    }

}