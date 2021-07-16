//SourceUnit: MegaTrustV2.sol

pragma solidity 0.5.13;

interface ITRC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function approve(address spender, uint256 value) external returns(bool);
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function allowance(address owner, address spender) external view returns(uint256);
}

library SafeMath {

    function add(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(a, b, 'SafeMath: addition overflow');
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

contract MegaTrustV2 {

    using SafeMath for uint256;

    uint256 public rate; // price 1 token/trx
    uint8 public dailyShare;
    ITRC20 public token;

    address payable public owner;
    address payable public addfund;
    address payable public trx_fee;
    address payable public mega_insurance;

    uint256 public cycles;
    uint8[] public refbns;
    uint8[] public reffs;
    uint256[] public refomset;
    uint32 public mxcycle = 100;

    uint8[] public poolbns;
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_deposited_token;
    uint256 public total_withdraw;
    uint256 public total_withdraw_token;

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
        uint40 withdraw_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
    }

    mapping(address => User) public users;
    mapping(address => uint8) public rating_user;
    mapping(address => uint256) public rating_bonus;
    mapping(address => uint256) public rating_bonus_claimed;
    mapping(address => uint256) public total_direct_omset;
    mapping(address => uint256) public deposit_amount_token;
    mapping(address => uint256) public total_deposit_tokens;

    mapping(address => uint256) public total_user_omset;
    mapping(address => mapping(uint8 => bool)) public user_level;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor(address payable _owner, address payable _addfund, address payable _trxfee, address payable _mega_insurance, ITRC20 _token) public {
        owner = _owner;

        token = _token;
        rate = 100000000;  // 1 token = 100 usd
        dailyShare = 100;
        
        addfund = _addfund;
        trx_fee = _trxfee;
        mega_insurance = _mega_insurance;
        
        refbns.push(20);    // lvl 1
        refbns.push(10);    // lvl 2
        refbns.push(10);    // lvl 3
        refbns.push(8);    // lvl 4
        refbns.push(8);    // lvl 5
        refbns.push(5);    // lvl 6
        refbns.push(5);    // lvl 7
        
        reffs.push(3);    // lvl 1
        reffs.push(5);    // lvl 2
        reffs.push(7);    // lvl 3
        reffs.push(9);    // lvl 4
        reffs.push(11);    // lvl 5
        reffs.push(13);    // lvl 6
        reffs.push(15);    // lvl 7

        poolbns.push(40);
        poolbns.push(30);
        poolbns.push(20);
        poolbns.push(10);

        cycles = 10000000000;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ACCESS_DENIED");
        _;
    }

    function _calcul(uint256 a, uint256 b, uint256 precision) internal pure returns (uint256) {

        return a*(10**precision)/b;
    }

    function setInsurace(address payable _insr) external onlyOwner {
        mega_insurance = _insr;
    }

    function setRate(uint256 _rate) external onlyOwner {
        require(_rate >= 0, 'Bad rate');
        rate = _rate;
    }

    function setDailyShare(uint8 _daily) external onlyOwner {
        require(_daily >= 0, 'Bad amount');
        dailyShare = _daily;
    }

    function setMxCycle(uint32 _mxcycle) external onlyOwner {
        require(_mxcycle >= 0, 'Bad amount');
        mxcycle = _mxcycle;
    }

    function setUserRating(address _addr, uint8 _rating, uint256 _bonus) external onlyOwner {
        require(_bonus >= 0, 'Bad amount');
        rating_user[_addr] = _rating;
        rating_bonus[_addr] = _bonus;
    }

    function setUserLevel(address _addr, uint8 _lvl, bool _sts) external onlyOwner {
        require(user_level[_addr][_lvl] != _sts, 'Bad status');
        user_level[_addr][_lvl] = _sts;
    }

    function() payable external {}

    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++;

            for(uint8 i = 0; i < refbns.length; i++) {
                if(_upline == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }

    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += (_amount * 5 / 1000);

        address upline = users[_addr].upline;

        if(upline == address(0)) return;
        
        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for(uint8 i = 0; i < poolbns.length; i++) {
            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint8 j = i + 1; j < poolbns.length; j++) {
                    if(pool_top[j] == upline) {
                        for(uint8 k = j; k <= poolbns.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(poolbns.length - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }

                pool_top[i] = upline;

                break;
            }
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < refbns.length; i++) {
            if(up == address(0)) break;
            
            if(users[up].referrals >= reffs[i] && user_level[up][i]==true) {
                uint256 bonus = _amount * refbns[i] / 100;
                
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

        for(uint8 i = 0; i < poolbns.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = draw_amount * poolbns[i] / 100;

            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;

            emit PoolPayout(pool_top[i], win);
        }
        
        for(uint8 i = 0; i < poolbns.length; i++) {
            pool_top[i] = address(0);
        }
    }

    function deposit(address _upline, uint256 _value) external {
        uint256 _amount_token = _calcul(_value, rate, uint256(token.decimals()));
        uint256 _token_balance = token.balanceOf(msg.sender);

        require(_amount_token > 0, "INVALID_TOKEN_AMOUNT");

        require(_token_balance >= _amount_token, "INSUFFICIENT_TOKEN");

        require(token.allowance(msg.sender,address(this))>0);

        _setUpline(msg.sender, _upline);

        address _addr = msg.sender;
        uint256 _amount = _value;

        require(users[_addr].upline != address(0) || _addr == owner, "No upline");

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_amount == users[_addr].deposit_amount && _amount <= cycles, "Bad amount");
        }
        else require(_amount >= 25000000 && _amount <= cycles, "Bad amount");

        require(token.transferFrom(msg.sender, address(this), _amount_token));
        
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;      
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].withdraw_time = 0;
        users[_addr].total_deposits += _amount;

        if(users[_addr].deposit_time <= 0) {
            total_direct_omset[_addr] = 0;
            rating_user[_addr] = 0;
            rating_bonus[_addr] = 0;
            rating_bonus_claimed[_addr] = 0;

            user_level[_addr][0] = false;
            user_level[_addr][1] = false;
            user_level[_addr][2] = false;
            user_level[_addr][3] = false;
            user_level[_addr][4] = false;
            user_level[_addr][5] = false;
            user_level[_addr][6] = false;
        }

        deposit_amount_token[_addr] = _amount_token; 
        total_deposit_tokens[_addr] += _amount_token;  

        total_deposited += _amount;
        total_deposited_token += _amount_token;
        
        emit NewDeposit(_addr, _amount);

        address upline = users[_addr].upline;
        if(upline != address(0)) {

            users[upline].direct_bonus += _amount / 10;

            total_direct_omset[upline] += _amount;

            emit DirectPayout(upline, _addr, _amount / 10);
        }

        _pollDeposits(_addr, _amount);

        if(pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
        }

        token.transfer(addfund, (_amount_token * 10 / 100));            // manager
        token.transfer(trx_fee, (_amount_token * 5 / 100));             // platform
        token.transfer(mega_insurance, (_amount_token * 35 / 1000));    // insurance
    }

    function withdraw() external {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);

        max_payout = max_payout * uint256(mxcycle / 100);
        
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

        users[msg.sender].withdraw_time = uint40(block.timestamp);

        uint256 amount_token = _calcul(to_payout, rate, uint256(token.decimals()));
        total_withdraw_token += amount_token;
        token.transfer(msg.sender, amount_token);

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }

    function withdrawReward() external {
        require(rating_bonus[msg.sender] > 0, "No Reward");

        uint256 _rating_bonus = rating_bonus[msg.sender];
        rating_bonus[msg.sender] -= _rating_bonus;
        rating_bonus_claimed[msg.sender] += _rating_bonus;

        uint256 amount_token = _calcul(_rating_bonus, rate, uint256(token.decimals()));
        token.transfer(msg.sender, amount_token);
    }
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 21 / 10;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {
            payout = (users[_addr].deposit_amount * ((block.timestamp - users[_addr].deposit_time) / 1 days) / dailyShare) - users[_addr].deposit_payouts;
            
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

    function userLastWithdraw(address _addr) view external returns(uint40 withdraw_time) {
        return (users[_addr].withdraw_time);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 _total_deposit_tokens, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, total_deposit_tokens[_addr], users[_addr].total_payouts, users[_addr].total_structure);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_deposited_token, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_users, total_deposited, total_deposited_token, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
    }

    function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < poolbns.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
}