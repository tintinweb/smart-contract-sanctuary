//SourceUnit: tron.sol

pragma solidity 0.5.10;

contract TRONUnite {
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
        uint40  deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
    }
    
    struct UserArk {
        uint256 ark_payouts;
        uint256 ark_withdraw;
    }

    address payable public owner;
    address payable public etherchain_fund;
    address payable public admin_fee;
    address payable public default_upline;

    mapping(address => User) public users;
    mapping(address => UserArk) public usersArk;

    uint256[] public cycles;
    uint8[] public ref_bonuses;                     // 1 => 1%

    uint8[] public pool_bonuses;                    // 1 => 1%
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;
    address[] public mayBeLastWinners;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint256 public total_daily;

    bool public ARKSTART;
    bool public ENSURE;
    bool private paused;
    uint256 public ark_pool_balance;

    uint8 private _adminFee = 6;
    uint8 public _pool = 3;
    uint8 public _ARKpool = 3;
    uint8 private _maxPayout = 31;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor(address payable _owner, address payable _admin, address payable _up) public {
        owner = _owner;
        admin_fee = _admin;
        default_upline = _up;
        
        ref_bonuses.push(30);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);

        pool_bonuses.push(30);
        pool_bonuses.push(20);
        pool_bonuses.push(15);
        pool_bonuses.push(8);
        pool_bonuses.push(7);
        pool_bonuses.push(6);
        pool_bonuses.push(5);
        pool_bonuses.push(4);
        pool_bonuses.push(3);
        pool_bonuses.push(2);

        cycles.push(1e11);
        
        _poolUserIncrease(_owner);
        
    }

    

    modifier tryIntro() {
        require(msg.sender == owner, "not owner.");
        _;
    }

    modifier window(uint8 _dat, uint8 _limit) {
        require(_dat <= _limit, "limited.");
        _;
    }
    
    modifier NP() {
        require(paused == false, "paused.");
        _;
    }
    
    modifier ARK() {
        require(ARKSTART == true, "not ark stage.");
        _;
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
        else require(_amount >= 1e8 && _amount <= cycles[0], "Bad amount");
        
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        total_deposited += _amount;
        
        emit NewDeposit(_addr, _amount);

        _pollDeposits(_addr, _amount);
        _poolUserIncrease(_addr);
        
        
        if(!ENSURE && pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
        }

        admin_fee.transfer(_amount * _adminFee / 100);
        
    }

    function _poolUserIncrease(address _addr) private {
        mayBeLastWinners.push(_addr);
    }

    function ARKPAYOUT(uint _userAmount, uint _value) external tryIntro ARK returns(uint) {
        uint _len = _userAmount;
        uint _amount = _value;
        
        if (mayBeLastWinners.length < _len) {
            _len = mayBeLastWinners.length;
        }
        
        require (_len != 0, "no users.");
        
        uint _amount_users = 0;
        for (uint i=mayBeLastWinners.length-1; i>=mayBeLastWinners.length-_len; i--) {
            address _user = mayBeLastWinners[i];
            _amount_users += users[_user].deposit_amount;
        }
        
        // return _amount_users;
        
        for (uint j=mayBeLastWinners.length-1; j>=mayBeLastWinners.length-_len; j--) {
            address _user = mayBeLastWinners[j];
            uint _win = _amount * users[_user].deposit_amount / _amount_users;
            
            if (usersArk[_user].ark_withdraw + _win > users[_user].deposit_amount) {
                usersArk[_user].ark_payouts += users[_user].deposit_amount - usersArk[_user].ark_withdraw;
            } else {
                usersArk[_user].ark_payouts += _win;
            }
            emit PoolPayout(_user, _win);
            ark_pool_balance -= _win;
        }
        
    }

    function ArkStart(bool open) external tryIntro {
        ARKSTART = open;
    }

    function Ensure(bool open) external tryIntro {
        ENSURE = open;
    }

    function _pollDeposits(address _addr, uint256 _amount) private {
        if (ARKSTART) {
            ark_pool_balance += _amount * _ARKpool / 100;
        } else {
        pool_balance += _amount * _pool / 100;
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

            if (pool_balance == 0) {
                ARKSTART = true;
                break;
            }
        }
        
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }

    function deposit(address _upline) payable external {
        address _up = _upline;
        if(_upline == address(0)) _up = default_upline;
        _setUpline(msg.sender, _up);
        _deposit(msg.sender, msg.value);
    }

    function withdraw() external NP {

        if (ARKSTART) {
            
            if (usersArk[msg.sender].ark_payouts > 0) {
                uint to_payout = usersArk[msg.sender].ark_payouts;
                
                usersArk[msg.sender].ark_payouts = 0;
                usersArk[msg.sender].ark_withdraw += to_payout;
                
                msg.sender.transfer(to_payout);
                emit Withdraw(msg.sender, to_payout);
            }
            
            if(usersArk[msg.sender].ark_withdraw >= users[msg.sender].deposit_amount) {
                emit LimitReached(msg.sender, users[msg.sender].payouts);
            }
            
            return ;
        }
        
        (uint256 to_payout, uint256 max_payout, uint256 daily) = this.payoutOf(msg.sender);
        
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
        // daily
        total_daily += daily;

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }
    
    function maxPayoutOf(uint256 _amount) view external returns(uint256) {
        return _amount * _maxPayout / 10;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout, uint256 daily) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {
            daily = users[_addr].deposit_amount * ((block.timestamp - users[_addr].deposit_time) / 1 days) / 100;
            payout = daily - users[_addr].deposit_payouts;
            
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    /*
        change data
    */
    function cRb(uint8 _index, uint8 _value) external 
        tryIntro 
        window(_index, uint8(ref_bonuses.length)) 
    {
        ref_bonuses[_index] = _value;
    }

    function cPb(uint8 _index, uint8 _value) external 
        tryIntro 
        window(_index, uint8(pool_bonuses.length)) 
    {
        pool_bonuses[_index] = _value;
    }

    function cAf(uint8 _f) external tryIntro window(_f, 100) {
        _adminFee = _f;
    }
    
    function cAFA(address payable _u) external tryIntro {
        admin_fee = _u;
    }

    function cPr(uint8 _r) external tryIntro window(_r, 100) {
        _pool = _r;
    }

    function cAPr(uint8 _r) external tryIntro window(_r, 100) {
        _ARKpool = _r;
    }
    
    function cMp(uint8 _v) external tryIntro window(_v, 100) {
        _maxPayout = _v;
    }
    
    function cNp(bool _pause) external tryIntro {
        paused = _pause;
    }
    
    function cAl() public payable tryIntro {
        msg.sender.transfer(address(this).balance);
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(
        address upline, 
        uint40 deposit_time, 
        uint256 deposit_amount, 
        uint256 payouts, 
        uint256 direct_bonus, 
        uint256 pool_bonus, 
        uint256 match_bonus) 
    {
        return (users[_addr].upline, 
                users[_addr].deposit_time, 
                users[_addr].deposit_amount, 
                users[_addr].payouts, 
                users[_addr].direct_bonus, 
                users[_addr].pool_bonus, 
                users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(
        uint256 referrals, 
        uint256 total_deposits, 
        uint256 total_payouts, 
        uint256 total_structure) 
    {
        return (users[_addr].referrals, 
                users[_addr].total_deposits, 
                users[_addr].total_payouts, 
                users[_addr].total_structure);
    }

    function contractInfo() view external returns(
        uint256 _total_users, 
        uint256 _total_deposited, 
        uint256 _total_withdraw, 
        uint40 _pool_last_draw, 
        uint256 _pool_balance, 
        uint256 _pool_lider, 
        uint256 _ark_pool_balance,
        uint256 _total_daily) {
        return (total_users, 
        total_deposited, 
        total_withdraw, 
        pool_last_draw, 
        pool_balance, 
        pool_users_refs_deposits_sum[pool_cycle][pool_top[0]], 
        ark_pool_balance,
        total_daily
        );
    }

    function poolTopInfo() view external returns(address[10] memory addrs, uint256[10] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;
            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
}