//SourceUnit: trxchain.sol

pragma solidity 0.5.10;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external ;
  function allowance(address owner, address spender) external view returns (uint256);
//   function decimals() external view returns (uint8);
}

contract TrxChain {
    IERC20 token;
    struct User {
        address upline; //上线
        uint256 cycle; //用户目前第几次存入
        uint256 referrals; //直接下限
        uint256 payouts; //当前cycle已经拿到的所有奖励
        uint256 deposit_payouts; //当前cycle已经拿的存储的奖励
        uint256 total_payouts; //所有cycle已经拿的所有类型的奖励
        uint256 pool_bonus; //目前可拿奖金池奖励
        uint256 match_bonus;  //目前可拿层级奖励
        uint256 deposit_amount; //最后一次的存储金额
        uint256 total_deposits; //累计存在的总金额
        uint40 deposit_time; //最后一次的存储时间
        uint40 withdraw_time; //最后一次的提现时间
        uint256 total_structure; //用户到ref_bonuses.length下限的人数
    }
    mapping(address => User) public users; //所有人的信息
    uint256 public mine_pool = 0; // 矿池总资金
    uint40 constant period = 1 days; //间隔period后，就可以获取算力奖励

    address payable public owner; //层级最高人
    address payable public admin; //管理员，部署合约的人

    uint8[] public ref_bonuses;//层级奖励百分比 1 表示 1%
    uint8[] public pool_bonuses;//最多荐人的奖励百分比
    uint8[] public attenuation_ratio;//衰减比例
    uint256[] public attenuation_bound;//衰减界限
    uint8 public current_bound = 0; //当前界限

    uint40 public pool_last_draw = uint40(block.timestamp);//最后一次奖池提现
    uint256 public pool_cycle;//奖池周期
    uint256 public pool_balance; //奖池金额
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum; //每个周期，第人的奖励
    mapping(uint8 => address) public pool_top; //每天推荐人数最多的4人

    uint256 public total_users = 1; //总用户
    uint256 public total_deposited; //总存入金额
    uint256 public total_withdraw; //总提现金额
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    event MineLimitReached(address indexed addr, uint256 amount);

    constructor(address payable _owner, address _token) public {
        admin = msg.sender;
        owner = _owner;
        token = IERC20(_token);

        ref_bonuses.push(10);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);

        pool_bonuses.push(40);
        pool_bonuses.push(30);
        pool_bonuses.push(20);
        pool_bonuses.push(10);

        attenuation_ratio.push(100);
        attenuation_ratio.push(80);
        attenuation_ratio.push(60);
        attenuation_ratio.push(40);
        attenuation_ratio.push(20);
        attenuation_ratio.push(20);

        attenuation_bound.push(1e13);
        attenuation_bound.push(3e13);
        attenuation_bound.push(5e13);
        attenuation_bound.push(7e13);
        attenuation_bound.push(9e13);
    }

    function setMinePool(uint256 _value) payable external {
        require(msg.sender == admin, "insufficient privilege");
        require(mine_pool == 0, "mine pool is already set up");
        require(_value > 0, "Please transfer in advance");
        require(token.balanceOf(address(this)) == _value, "value not legal");
        mine_pool = _value;
    }


    function() payable external {
        // _deposit(msg.sender, msg.value);
    }

    function _setUpline(address _addr, address _upline) private {
        if (owner == _addr) {//owner不能有上限,但可以存钱。
            return;
        }
        require(_upline != address(0), "No upline");
        require(_upline != _addr, "upline is self");
        // if (_addr == _upline) { //上限是自己的情况
        //     if (users[_addr].upline == address(0)) {
        //         users[_addr].upline = _upline;
        //         total_users++;
        //         emit Upline(_addr, _upline);
        //     }
        //     return;
        // }
        if(users[_addr].upline == address(0) && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_upline].referrals++;
            users[_addr].upline = _upline;
            total_users++;
            emit Upline(_addr, _upline);
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                users[_upline].total_structure++;
                if (_upline == users[_upline].upline) { //下一个upline是自己
                    break;
                }
                _upline = users[_upline].upline;
            }
        }
    }

    function _deposit(address _addr, uint256 _amount) private {
        require(_amount > 0, "Bad amount");
        require(mine_pool > total_withdraw, "There are no more mines");

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
        }
        users[_addr].payouts = 0;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].total_deposits += _amount;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].withdraw_time = users[_addr].deposit_time; 

        total_deposited += _amount;
        
        emit NewDeposit(_addr, _amount);

        _pollDeposits(_addr, _amount);

        if(pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
        }
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

    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = pool_balance / 10;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = draw_amount * pool_bonuses[i] / 100;
            if (win == 0) {
                continue;
            }

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
        uint256 value = token.allowance(msg.sender, address(this));
        token.transferFrom(msg.sender, address(this), value);
        _deposit(msg.sender, value);
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
            users[msg.sender].total_payouts += to_payout;

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
            users[msg.sender].total_payouts += pool_bonus;
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
            users[msg.sender].total_payouts += match_bonus;
            to_payout += match_bonus;
        }

        require(to_payout > 0, "Zero payout");
        
        if (total_withdraw + to_payout > mine_pool) {
            to_payout = mine_pool - total_withdraw;
            require(to_payout > 0, "Zero payout");
            emit MineLimitReached(msg.sender, mine_pool);
        }
        total_withdraw += to_payout;
        if (total_withdraw >= attenuation_bound[current_bound]) {
            if (current_bound < attenuation_bound.length -1) {
                current_bound++;
            }
        }

        users[msg.sender].withdraw_time = uint40(uint40(block.timestamp) - (block.timestamp - users[msg.sender].withdraw_time) % period);
        token.transfer(msg.sender, to_payout);

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }

    //层级奖励
    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        address pre_up = address(0);
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            if(up == pre_up) break; //上限是自己表示没有上线
            
            uint256 bonus = _amount * ref_bonuses[i] / 100;
            if (bonus > 0) {
                users[up].match_bonus += bonus;
                emit MatchPayout(up, _addr, bonus);
            }

            pre_up = up;
            up = users[up].upline;
        }
    }

    
    function maxPayoutOf(uint256 _amount) view external returns(uint256) {
        return _amount * 3; //算力是存钱的3倍
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);
        if (users[_addr].payouts >= max_payout) { //当前轮已经全部拿完了。
            payout = 0;
        } else if(users[_addr].deposit_payouts < max_payout) {
            // payout = (users[_addr].deposit_amount * ((block.timestamp - users[_addr].withdraw_time) / period) / 100) * attenuation_ratio[current_bound] / 100;
            
            // if(users[_addr].deposit_payouts + payout > max_payout) {
            //     payout = max_payout - users[_addr].deposit_payouts;
            // }
            uint256 min_payout = max_payout / 300 * attenuation_ratio[current_bound] / 100; //每次的奖励
            uint256 curr_times = (block.timestamp - users[_addr].withdraw_time) / period;//可领奖次数
            payout = curr_times * min_payout; //当前时间，用户应该可以直接领取的奖励
            if (users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
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

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider, uint256 _mine_pool) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]], mine_pool);
    }

    function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
}